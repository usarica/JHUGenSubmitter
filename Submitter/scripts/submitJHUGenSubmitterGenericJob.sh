#!/bin/bash

SCRIPTNAME="$1"
FCN="$2"
FCNARGS="$3"
QUEUE="$4"
OUTDIR="$5"

echo "Calling the main submission script with the following arguments:"
echo "SCRIPTNAME: ${SCRIPTNAME}"
echo "FCN: ${FCN}"
echo "FCNARGS: ${FCNARGS}"
echo "QUEUE: ${QUEUE}"
echo "OUTDIR: ${OUTDIR}"


if [[ "$OUTDIR" == "" ]];then
  echo "You must set the output directory!"
  exit 1
fi

CMSENVDIR=$CMSSW_BASE
if [ -z $CMSENVDIR ];then
  echo "Set up CMSSW first!"
  exit 1
fi


LOGSDIR=$OUTDIR"/Logs"
mkdir -p $LOGSDIR

extLog=$FCN
if [[ "$FCNARGS" != "" ]];then
  fcnargname=""
  fcnarglist=($(echo $FCNARGS))
  for farg in "${fcnarglist[@]}";do
    farg=${farg//"\""}
    if [[ "$farg" == "outfile="* ]];then
      fcnargname=$farg
      fcnargname=${fcnargname//"outfile="}
      break
    fi
  done
  if [[ "$fcnargname" == "" ]];then
    fcnargname=${FCNARGS//" "/"_"}
  fi
  fcnargname=${fcnargname//"="/"_"}
  fcnargname=${fcnargname//".root"}
  fcnargname=${fcnargname//\"}
  fcnargname=${fcnargname//\!}
  fcnargname=${fcnargname//\\}
  fcnargname=${fcnargname//"("}
  fcnargname=${fcnargname//")"}
  fcnargname=${fcnargname//","/"_"}
  extLog=$FCN"_"$fcnargname
fi


if [[ -f $SCRIPTNAME ]]; then
  echo "File "$SCRIPTNAME" exists."

  if [[ "$SCRIPTNAME" == *"."* ]];then
    SCRIPTSO=${SCRIPTNAME%.*}"_"${SCRIPTNAME##*.}".so"
    if [[ ! -f $SCRIPTSO ]]; then
      echo "Compiling "$SCRIPTNAME"..."
      root -l -b -q -e "gROOT->ProcessLine(\".x loadLib.C\"); gROOT->ProcessLine(\".L "$SCRIPTNAME"+\");"
    fi
  fi

  hname=$(hostname)
  echo $hname
  if [[ "$hname" == *"lxplus"* ]] || [[ "$hname" == *"ucsd"* ]];then
    echo "Host is on LXPLUS or UCSD, so need to use HTCONDOR"
    THEQUEUE="vanilla"
    if [[ "$QUEUE" != "default" ]];then
      THEQUEUE=$QUEUE
    fi
    checkGridProxy.sh
    TARFILE="jhugensub.tar"
    if [ ! -e ${OUTDIR}/${TARFILE} ];then
      createJHUGenSubmitterTarball.sh
      mv ${TARFILE} ${OUTDIR}/
    fi
    configureJHUGenSubmitterCondorJob.py --tarfile="$TARFILE" --batchqueue="$THEQUEUE" --outdir="$OUTDIR" --outlog="Logs/log_$extLog" --errlog="Logs/err_$extLog" --batchscript="submitJHUGenSubmitterGenericJob.condor.sh" --script="$SCRIPTNAME" --fcn="$FCN" --fcnargs="$FCNARGS"
  elif [[ "$hname" == *"login-node"* ]] || [[ "$hname" == *"bc-login"* ]]; then
    echo "Host is on MARCC, so need to use SLURM batch"
    THEQUEUE="lrgmem"
    if [[ "$QUEUE" != "default" ]];then
      THEQUEUE=$QUEUE
    fi
    sbatch --output=$LOGSDIR"/log_"$extLog".txt" --error=$LOGSDIR"/err_"$extLog".err" --partition=$THEQUEUE submitJHUGenSubmitterGenericJob.slurm.sh "$CMSENVDIR" "$SCRIPTNAME" "$FCN" "$FCNARGS"
  fi

fi
