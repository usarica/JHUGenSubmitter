#!/bin/bash

INFILE=$1
DATE=$2
OUTPUTDIR=$3
CONDOROUTDIR=$4

SCRIPTNAME="./JHUGen"
QUEUE="default"

hname=$(hostname)

CONDORSITE="DUMMY"
if [[ "$hname" == *"lxplus"* ]];then
  echo "Setting default CONDORSITE to cern.ch"
  CONDORSITE="cern.ch"
elif [[ "$hname" == *"ucsd"* ]];then
  echo "Setting default CONDORSITE to t2.ucsd.edu"
  CONDORSITE="t2.ucsd.edu"
fi

if [[ "$OUTPUTDIR" == "" ]];then
  OUTPUTDIR="./output"
fi
if [[ "$DATE" == "" ]];then
  DATE=$(date +%y%m%d)
fi

OUTDIR="${OUTPUTDIR}/${DATE}"

mkdir -p $OUTDIR

TARFILE="jhugensub.tar"
if [ ! -e ${OUTDIR}/${TARFILE} ];then
  cd ${OUTDIR}
  createJHUGenSubmitterTarball.sh
  cd -
fi


while IFS='' read -r line || [[ -n "$line" ]]; do
  THECONDORSITE="${CONDORSITE+x}"
  THECONDOROUTDIR="${CONDOROUTDIR+x}"
  fcnarglist=($(echo $line))
  fcnargname=""
  fcnargnameextra=""
  fcnargnametmp=""
  for fargo in "${fcnarglist[@]}";do
    farg="${fargo//\"}"
    fargl="$(echo $farg | awk '{print tolower($0)}')"
    if [[ "$fargl" == "datafile="* ]];then
      fcnargname="$farg"
      fcnargname="${fcnargname#*=}"
      fcnargname="${fcnargname//.lhe}"
      fcnargname="${fcnargname##*/}"
    elif [[ "$fargl" == "vbfoffsh_run="* ]];then
      fcnargnametmp="$farg"
      fcnargnametmp="${fcnargnametmp#*=}"
      fcnargnameextra=$fcnargnameextra"_"$fcnargnametmp
    elif [[ "$fargl" == "condorsite="* ]];then
      line="${line//$fargo}"
      fcnargnametmp="$fargo"
      fcnargnametmp="${fcnargnametmp#*=}"
      THECONDORSITE="$fcnargnametmp"
    elif [[ "$fargl" == "condoroutdir="* ]];then
      line="${line//$fargo}"
      fcnargnametmp="$farg"
      fcnargnametmp="${fcnargnametmp#*=}"
      THECONDOROUTDIR="$fcnargnametmp"
    fi
  done
  line="${line//  / }" # replace double whitespace with single
  line="${line## }" # strip leading space
  line="${line%% }" # strip trailing space
  if [[ "${THECONDORSITE+x}" != "DUMMY" ]] && [[ -z "${THECONDOROUTDIR+x}" ]]; then
    echo "Need to set THECONDOROUTDIR"
    continue
  fi
  if [[ "$fcnargnameextra" != "" ]];then
    fcnargname=$fcnargname"_"$fcnargnameextra
  fi
  if [[ ! -z $fcnargname ]];then
    theOutdir="${OUTDIR}/${fcnargname}"
    mkdir -p $theOutdir
    ln -sf ${PWD}/${OUTDIR}/${TARFILE} ${PWD}/${theOutdir}/

    submitJHUGenSubmitterGenericJob.sh "$SCRIPTNAME" "$line" "$QUEUE" "$theOutdir" "$THECONDORSITE" "$THECONDOROUTDIR"
  fi
done < "$INFILE"
