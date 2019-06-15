#!/bin/sh


CMSSWVERSION="$1"
SCRAMARCH="$2"
SUBMIT_DIR="$3" # Must be within $CMSSW_BASE/src/
TARFILE="$4"
RUNFILE="$5"
FCN="$6"
FCNARGS="$7"
#FCNARGS=${FCNARGS//".oO[SPACE]Oo."/" "} # This is a special replacement to work around arguments with spaces
#FCNARGS=${FCNARGS//".oO[DOUBLEQUOTE]Oo."/"\""} # This is a special replacement to work around arguments with double quotes
#FCNARGS=${FCNARGS//".oO[BACKLASH]Oo."/"\\"} # This is a special replacement to work around arguments with backlashes

# Make sure OUTPUTNAME doesn't have .root since we add it manually
#OUTPUTNAME=$(echo $OUTPUTNAME | sed 's/\.root//')

export SCRAM_ARCH=${SCRAMARCH}

echo -e "\n--- begin header output ---\n" #                     <----- section division
echo "CMSSWVERSION: $CMSSWVERSION"
echo "SCRAMARCH: $SCRAMARCH"
echo "SUBMIT_DIR: $SUBMIT_DIR"
echo "TARFILE: $TARFILE"
echo "RUNFILE: $RUNFILE"
echo "FCN: $FCN"
echo "FCNARGS: $FCNARGS"

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
  eval `scramv1 project CMSSW $CMSSWVERSION`
  cd $CMSSWVERSION
fi

# Setup the CMSSW environment
eval `scramv1 runtime -sh`
echo "CMSSW_BASE: ${CMSSW_BASE}"

# Remove the tarfile
if [ -e ../${TARFILE} ]; then
  mv ../${TARFILE} ${TARFILE}
  tar xf ${TARFILE}
  rm ${TARFILE}
fi

# Check the lib area as uploaded
echo "=============================="
echo "lib/${SCRAM_ARCH} as uploaded:"
ls lib/${SCRAM_ARCH}
echo "=============================="

# Compile cmstas/CORE first
cd src/cmstas/CORE
make clean &>> compilation.log
make -j 12 &>> compilation.log
CORE_COMPILE_STATUS=$?
if [ $CORE_COMPILE_STATUS != 0 ];then
  echo "cmstas/CORE compilation exited with error ${CORE_COMPILE_STATUS}. Printing the log:"
  cat compilation.log
fi
rm -f compilation.log
cd ../../../

# Clean CMSSW-related compilation objects and print the lib area afterward
scramv1 b clean &>> compilation.log
echo "================================="
echo "lib/${SCRAM_ARCH} after cleaning:"
ls lib/${SCRAM_ARCH}
echo "================================="

# Compile CMSSW-dependent packages
scramv1 b -j 12 &>> compilation.log
CMSSW_COMPILE_STATUS=$?
if [ $CMSSW_COMPILE_STATUS != 0 ];then
  echo "CMSSW compilation exited with error ${CMSSW_COMPILE_STATUS}. Printing the log:"
  cat compilation.log
fi
rm -f compilation.log

# Needed to locate the include directory of MELA classes. It can get lost.
export ROOT_INCLUDE_PATH=${ROOT_INCLUDE_PATH}:${CMSSW_BASE}/src/ZZMatrixElement/MELA/interface
# Ensure CMSSW can find libmcfm
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${CMSSW_BASE}/src/ZZMatrixElement/MELA/data/${SCRAM_ARCH}
# Do not do the one below instead of the above; it will create problems when loading the MELA library interactively
# cp ${CMSSW_BASE}/src/ZZMatrixElement/MELA/data/${SCRAM_ARCH}/*.so ${CMSSW_BASE}/lib/${SCRAM_ARCH}/


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
RUN_CMD=$(runGenericROOTCommand.py --loadlib="loadLib.C" --script="$RUNFILE" --function="$FCN" --command="$FCNARGS" --recompile --dry) # Must force recompilation
if [[ "$RUN_CMD" == "Running "* ]];then
  echo "$RUN_CMD"
  RUN_CMD=${RUN_CMD//"Running "}
  eval "$RUN_CMD"
  RUN_STATUS=$?
  if [ $RUN_STATUS != 0 ]; then
    echo "Run has crashed with exit code ${RUN_STATUS}"
    exit 1
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
# In cases where transfer through the script fails
if [[ -f "EXTERNAL_TRANSFER_CMD_LIST.LST" ]];then
  echo -e "\n--- Begin EXTERNAL TRANSFER ---\n"
  while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "Executing ${line} from the transfer file"
    $line
    TRANSFER_STATUS=$?
    if [ $TRANSFER_STATUS != 0 ]; then
      echo " - Transfer crashed with exit code ${TRANSFER_STATUS}"
    fi
  done < "EXTERNAL_TRANSFER_CMD_LIST.LST"
  echo -e "\n--- End EXTERNAL TRANSFER ---\n"
fi
##############


echo "Submission directory after running: ls -lrth"
ls -lrth

echo "time at end: $(date +%s)"
