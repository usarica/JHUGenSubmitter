#!/bin/sh

getvarpaths(){
  for var in "$@";do
    tmppath=${var//:/ }
    for p in $(echo $tmppath);do
      if [[ -e $p ]];then
        echo $p
      fi
    done
  done  
}
searchfileinvar(){
  for d in $(getvarpaths $1);do
    for f in $(ls $d | grep $2);do
      echo "$d/$f"
    done
  done
}


CMSSWVERSION="$1"
SCRAMARCH="$2"
SUBMIT_DIR="$3" # Must be within $CMSSW_BASE/src/
TARFILE="$4"
RUNFILE="$5"
FCNARGS="$6"
CONDORSITE="$7"
CONDOROUTDIR="$8"

export SCRAM_ARCH=${SCRAMARCH}

echo -e "\n--- begin header output ---\n" #                     <----- section division
echo "CMSSWVERSION: $CMSSWVERSION"
echo "SCRAMARCH: $SCRAMARCH"
echo "SUBMIT_DIR: $SUBMIT_DIR"
echo "TARFILE: $TARFILE"
echo "RUNFILE: $RUNFILE"
echo "FCNARGS: $FCNARGS"
echo "CONDORSITE: $CONDORSITE"
echo "CONDOROUTDIR: $CONDOROUTDIR"

echo "GLIDEIN_CMSSite: $GLIDEIN_CMSSite"
echo "hostname: $(hostname)"
echo "uname -a: $(uname -a)"
echo "time: $(date +%s)"
echo "args: $@"
echo "tag: $(getjobad tag)"
echo "taskname: $(getjobad taskname)"
echo -e "\n--- end header output ---\n" #                       <----- section division

echo -e "\n--- begin memory specifications ---\n" #                     <----- section division
ulimit -a
echo -e "\n--- end memory specifications ---\n" #                     <----- section division


if [ -r "$OSGVO_CMSSW_Path"/cmsset_default.sh ]; then
  echo "sourcing environment: source $OSGVO_CMSSW_Path/cmsset_default.sh"
  source "$OSGVO_CMSSW_Path"/cmsset_default.sh
elif [ -r "$OSG_APP"/cmssoft/cms/cmsset_default.sh ]; then
  echo "sourcing environment: source $OSG_APP/cmssoft/cms/cmsset_default.sh"
  source "$OSG_APP"/cmssoft/cms/cmsset_default.sh
elif [ -r /cvmfs/cms.cern.ch/cmsset_default.sh ]; then
  echo "sourcing environment: source /cvmfs/cms.cern.ch/cmsset_default.sh"
  source /cvmfs/cms.cern.ch/cmsset_default.sh
else
  echo "ERROR! Couldn't find $OSGVO_CMSSW_Path/cmsset_default.sh or /cvmfs/cms.cern.ch/cmsset_default.sh or $OSG_APP/cmssoft/cms/cmsset_default.sh"
  exit 1
fi

INITIALDIR=$(pwd)

# If the first file in the tarball filelist starts with CMSSW, it is a
# tarball made outside of the full CMSSW directory and must be handled
# differently
if [ ! -z $(tar -tf ${TARFILE} | head -n 1 | grep "^CMSSW") ]; then
  echo "This is a full cmssw tar file."
  tar xf ${TARFILE}
  cd $CMSSWVERSION
  echo "Current directory ${PWD} =? ${CMSSWVERSION}"
  echo "Running ProjectRename"
  scramv1 b ProjectRename
else
  # Setup the CMSSW area
  echo "This is a selective CMSSW tar file."
  eval $(scramv1 project CMSSW $CMSSWVERSION)
  cd $CMSSWVERSION
fi


# Setup the CMSSW environment
eval $(scramv1 runtime -sh)
echo "CMSSW_BASE: ${CMSSW_BASE}"
echo "SCRAM_ARCH: ${SCRAM_ARCH}"
echo "LD_LIBRARY_PATH: ${LD_LIBRARY_PATH-\'unset\'}"
echo "PYTHONPATH: ${PYTHONPATH-\'unset\'}"
echo "ROOT_INCLUDE_PATH: ${ROOT_INCLUDE_PATH-\'unset\'}"



# Ensure gfortran can be found
if [[ "$SCRAM_ARCH" == "slc7"* ]];then
  gcc --version
  g++ --version
  gfortran --version

  gfortran --print-file-name libgfortran.so
  gcc --print-file-name libgfortran.so

  echo $(ldconfig -p | grep gfortran)

  LIBGFORTRANDIR="$(ldconfig -p | grep gfortran | awk '{print($4)}')"
  LIBGFORTRANDIR="${LIBGFORTRANDIR%/*}"
  echo "gfortran installed in ${LIBGFORTRANDIR-\'unset\'}"
  if [[ ! -z "${LIBGFORTRANDIR+x}" ]];then
    beg=""
    if [[ -z "${LD_LIBRARY_PATH+x}" ]]; then
      beg=""
    else
      beg="${LD_LIBRARY_PATH}:"
    fi
    export LD_LIBRARY_PATH=$beg:$LIBGFORTRANDIR
  fi
fi


# Remove the tarfile
if [ -e $INITIALDIR/${TARFILE} ]; then
  echo "Moving the tarball from $INITIALDIR/${TARFILE} into "$(pwd)
  mv $INITIALDIR/${TARFILE} ./
  tar xf ${TARFILE}
  rm ${TARFILE}
else
  echo "The tarball does not exist in $INITIALDIR/${TARFILE}"
fi

# Check the lib area as uploaded
echo "=============================="
echo "${CMSSW_BASE}/lib/${SCRAM_ARCH} as uploaded:"
ls ${CMSSW_BASE}/lib/${SCRAM_ARCH}
echo "=============================="


# Clean CMSSW-related compilation objects and print the lib area afterward
scramv1 b clean &>> compilation.log
echo "================================="
echo "${CMSSW_BASE}/lib/${SCRAM_ARCH} after cleaning:"
ls ${CMSSW_BASE}/lib/${SCRAM_ARCH}
echo "================================="

echo "================================="
echo "Contents of ${CMSSW_BASE}/src:"
ls -la ${CMSSW_BASE}/src
echo "================================="

echo "================================="
echo "Contents of /usr/lib/x86_64-linux-gnu:"
ls -la /usr/lib/x86_64-linux-gnu
echo "================================="


# MELA includes
JHUGENDIR=${CMSSW_BASE}/src/JHUGen/JHUGenerator
MCFMDIR=${CMSSW_BASE}/src/JHUGen/MCFM-JHUGen
MELADIR=${CMSSW_BASE}/src/JHUGen/JHUGenMELA/MELA
ZZMEDIR=${CMSSW_BASE}/src/ZZMatrixElement
if [[ ! -d $JHUGENDIR ]];then
  echo "JHUGENDIR=$JHUGENDIR does not exist!"
  exit 1
fi
if [[ ! -d $MELADIR ]];then
  echo "MELADIR=$MELADIR does not exist!"
  exit 1
fi
if [[ ! -d $ZZMEDIR ]];then
  echo "ZZMEDIR=$ZZMEDIR does not exist!"
  exit 1
fi
end=""
# Ensure CMSSW can find libmcfm
if [[ -z "${LD_LIBRARY_PATH+x}" ]]; then
  end=""
else
  end=":${LD_LIBRARY_PATH}"
fi
export LD_LIBRARY_PATH=$MELADIR/data/$SCRAM_ARCH$end
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${CMSSW_BASE}/src/ZZMatrixElement/MELA/data/${SCRAM_ARCH}
echo "LD_LIBRARY_PATH:";getvarpaths ${LD_LIBRARY_PATH}
# Ensure LHAPDF library path is also included in LD_LIBRARY_PATH
if [[ ! -z "${LHAPDF_DATA_PATH+x}" ]]; then
  export LD_LIBRARY_PATH=${LHAPDF_DATA_PATH}:${LD_LIBRARY_PATH}
else
  echo "CMSSW  configuration error: LHAPDF_DATA_PATH is undefined!"
  exit 1
fi
# Ensure CMSSW can find MELApy
if [[ -z "${PYTHONPATH+x}" ]]; then
  end=""
else
  end=":${PYTHONPATH}"
fi 
export PYTHONPATH=$MELADIR/python$end
echo "PYHONPATH:";getvarpaths ${PYTHONPATH}
# Needed to locate the include directory of MELA classes. It can get lost.
if [[ -z "${ROOT_INCLUDE_PATH+x}" ]]; then
  end=""
else
  end=":${ROOT_INCLUDE_PATH}"
fi
export ROOT_INCLUDE_PATH=$MELADIR/interface$end
export ROOT_INCLUDE_PATH=${ROOT_INCLUDE_PATH}:${CMSSW_BASE}/src/ZZMatrixElement/MELA/interface
echo "ROOT_INCLUDE_PATH:";getvarpaths ${ROOT_INCLUDE_PATH}


echo "Searching for the versions for libgfortran in LD_LIBRARY_PATH:"
searchfileinvar $LD_LIBRARY_PATH gfort

# Compile MCFM
let doCompileMCFM=0
if [[ $doCompileMCFM -eq 1 ]];then
  echo "Entering MCFMDIR=${MCFMDIR}"
  cd $MCFMDIR
  ./compile.sh -j 12 &>> compilation.log
  COMPILE_STATUS=$?
  if [ $COMPILE_STATUS != 0 ];then
    echo "MCFM compilation exited with error ${COMPILE_STATUS}. Printing the log:"
    cat compilation.log
  else
    cp ${MCFMDIR}/obj/libmcfm* ${ZZMEDIR}/MELA/data/${SCRAM_ARCH}/ # Copy into ZZME as well. The script already copies into JHUGenMELA.
  fi
  rm -f compilation.log
  cd -
fi

# Compile MELA
echo "Entering MELADIR=${MELADIR}"
cd $MELADIR
./setup.sh clean
./setup.sh -j 12 &>> compilation.log
COMPILE_STATUS=$?
if [ $COMPILE_STATUS != 0 ];then
  echo "MELA compilation exited with error ${COMPILE_STATUS}. Printing the log:"
  cat compilation.log
fi
rm -f compilation.log
cd -

# Compile JHUGen
echo "Entering JHUGENDIR=${JHUGENDIR}"
cd $JHUGENDIR
make clean
make &>> compilation.log
COMPILE_STATUS=$?
if [ $COMPILE_STATUS != 0 ];then
  echo "JHUGenerator compilation exited with error ${COMPILE_STATUS}. Printing the log:"
  cat compilation.log
fi
rm -f compilation.log
cd -

# Compile ZZMatrixElement
echo "Entering ZZMEDIR=${ZZMEDIR}"
cd $ZZMEDIR
./setup.sh clean
./setup.sh -j 12 &>> compilation.log
COMPILE_STATUS=$?
if [ $COMPILE_STATUS != 0 ];then
  echo "ZZMatrixElement compilation exited with error ${COMPILE_STATUS}. Printing the log:"
  cat compilation.log
fi
rm -f compilation.log
cd -

# Compile CMSSW-dependent packages
scramv1 b -j 12 &>> compilation.log
COMPILE_STATUS=$?
if [ $COMPILE_STATUS != 0 ];then
  echo "CMSSW compilation exited with error ${COMPILE_STATUS}. Printing the log:"
  cat compilation.log
fi
rm -f compilation.log


# Go into the submission directory within $CMSSW_BASE/src
cd src/$SUBMIT_DIR

echo "Submission directory before running: ls -lrth"
ls -lrth


##############
# ACTUAL RUN #
##############
# Transfer needs to be done through the script.
# Script is actually run through bash to eliminate the extra processor consumption by python
echo -e "\n--- Begin RUN ---\n"
RUN_CMD=$(runGenericExecutable.py --exe="$RUNFILE" --command="$FCNARGS" --dry) # Must run it dry
if [[ "$RUN_CMD" == "Running "* ]];then
  echo "$RUN_CMD"
  RUN_CMD="${RUN_CMD//Running }"

  let process=0
  let reqallgrids=0

  runargs=($(echo $RUN_CMD))
  for fargo in "${runargs[@]}";do
    farg="${fargo//\"}"
    fargl="$(echo $farg | awk '{print tolower($0)}')"
    if [[ "$fargl" == "process="* ]];then
      tmparg="$farg"
      tmparg="${tmparg#*=}"
      let process=$tmparg
    elif [[ "$fargl" == *"vbfoffsh_run=all"* ]];then
      let reqallgrids=1
    fi
  done

  if [[ $reqallgrids -eq 1 ]];then
    let gridrun=0
    let gridrunmax=0
    if [[ $process -ge 66 ]] && [[ $process -le 68 ]];then
      let gridrun=1
      let gridrunmax=164
    elif [[ $process -ge 69 ]];then
      let gridrun=1
      let gridrunmax=175
    elif [[ $process -ge 70 ]] && [[ $process -le 72 ]];then
      let gridrun=1
      let gridrunmax=84
    fi
    echo "Grid run range for Process=$process: [${gridrun}, ${gridrunmax}]"
    while [ $gridrun -le $gridrunmax ];do
      TMP_CMD="$RUN_CMD"
      TMP_CMD="${TMP_CMD//VBFoffsh_run=all/VBFoffsh_run=$gridrun}"
      echo "Running command instance $TMP_CMD"
      eval "$TMP_CMD"
      RUN_STATUS=$?
      if [ $RUN_STATUS != 0 ]; then
        echo "Run has crashed with exit code ${RUN_STATUS}"
        exit 1
      fi
      let gridrun=$gridrun+1
    done
  else
    eval "$RUN_CMD"
    RUN_STATUS=$?
    if [ $RUN_STATUS != 0 ]; then
      echo "Run has crashed with exit code ${RUN_STATUS}"
      exit 1
    fi
  fi


else
  echo "Run command ${RUN_CMD} is invalid."
  exit 1
fi
echo -e "\n--- End RUN ---\n"
##############


##################
# TRANSFER FILES #
##################
fcnarglist=($(echo $RUN_CMD))
THEDATAFILECORE=""
THEDATADIR="."
for fargo in "${fcnarglist[@]}";do
  farg="${fargo//\"}"
  fargl="$(echo $farg | awk '{print tolower($0)}')"
  if [[ "$fargl" == "datafile="* ]];then
    echo "Extracting the data file base name from $farg"
    fcnargname="$farg"
    fcnargname="${fcnargname#*=}"
    fcnargname="${fcnargname//.lhe}"
    THEDATAFILECORE="${fcnargname##*/}"
    if [[ "$fcnargname" == *"/"* ]];then
      THEDATADIR="${fcnargname%/*}"
    fi
    echo "Data file directory: ${THEDATADIR}"
    echo "Data file base name: ${THEDATAFILECORE}"
  fi
done
if [[ ! -z ${THEDATAFILECORE+x} ]];then
  echo "Searching for ${THEDATADIR}/${THEDATAFILECORE} derivatives."
  current_transfer_dir=$(pwd)
  tarcontents=""
  for THEDATAFILE in $(ls ${THEDATADIR} | grep -e ${THEDATAFILECORE} | grep -e ".lhe" -e ".CSmax.bin" -e "gridinfo.txt" -e ".grid" -e "commandline");do
    if [[ -z "$tarcontents" ]];then
      tarcontents="${THEDATADIR}/${THEDATAFILE}"
    else
      tarcontents="${tarcontents} ${THEDATADIR}/${THEDATAFILE}"
    fi
  done
  transfer_tarname="${THEDATAFILECORE}.tar"
  tar Jcvf $transfer_tarname $tarcontents
  TARCMD_STATUS=$?
  if [ $TARCMD_STATUS != 0 ];then
    echo "Tar file $transfer_tarname could not be created. The tar ball was supposed to contain"
    echo "=> < "$tarcontents" >"
  else
    copyFromCondorToSite.sh ${current_transfer_dir} ${transfer_tarname} ${CONDORSITE} ${CONDOROUTDIR}
    TRANSFER_STATUS=$?
    if [ $TRANSFER_STATUS != 0 ]; then
      echo " - Transfer crashed with exit code ${TRANSFER_STATUS}"
    fi
  fi
fi
##############


echo "Submission directory after running: ls -lrth"
ls -lrth

echo "time at end: $(date +%s)"
