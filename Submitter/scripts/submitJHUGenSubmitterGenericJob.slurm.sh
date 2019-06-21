#!/bin/sh

#SBATCH --time=72:0:0
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=2
#SBATCH --mem=32G
#SBATCH --mail-type=FAIL,TIME_LIMIT_80
#SBATCH --mail-user=usarica1@jhu.edu

RUNDIR=${SLURM_SUBMIT_DIR}
cd $RUNDIR
echo "SLURM job running in: " `pwd`

# ROOT
# xpm (needed for ROOT)
export CPATH="/work-zfs/lhc/usarica/libXpm-3.5.11/include:$CPATH"
source /work-zfs/lhc/usarica/ROOT/bin/thisroot.sh

# CMSSW
source /work-zfs/lhc/cms7/cmsset_default.sh
module load boost/1.60.0
export LIBRARY_PATH=$LIBRARY_PATH:/cm/shared/apps/boost/1.60.0/lib
export CPATH=$CPATH:/cm/shared/apps/boost/1.60.0/include

CMSENVDIR=$1
runfile=$2
extcmd=$3


cd $CMSENVDIR
eval `scram runtime -sh`
echo $CMSSW_VERSION

# MELA includes
JHUGENDIR=${CMSSW_BASE}/src/JHUGen/JHUGenerator
MELADIR=${CMSSW_BASE}/src/JHUGen/JHUGenMELA/MELA
end=""
# Ensure CMSSW can find libmcfm
if [[ -z "${LD_LIBRARY_PATH+x}" ]]; then
  end=""
else
  end=":${LD_LIBRARY_PATH}"
fi
export LD_LIBRARY_PATH=$MELADIR/data/$SCRAM_ARCH$end
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
# Needed to locate the include directory of MELA classes. It can get lost.
if [[ -z "${ROOT_INCLUDE_PATH+x}" ]]; then
  end=""
else
  end=":${ROOT_INCLUDE_PATH}"
fi
export ROOT_INCLUDE_PATH=$MELADIR/interface$end

cd $RUNDIR

echo "Host name: "$(hostname)

runGenericExecutable.py --exe="$runfile" --command="$extcmd"
