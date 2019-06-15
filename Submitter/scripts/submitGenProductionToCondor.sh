#!/bin/bash

INFILE=$1
OUTPUTDIR=$2
DATE=$3

SCRIPTNAME="doGenProduction.cc"
FCN="doGenProduction"
QUEUE="default"

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
  createJHUGenSubmitterTarball.sh
  mv ${TARFILE} ${OUTDIR}/
fi


while IFS='' read -r line || [[ -n "$line" ]]; do
  fcnarglist=($(echo $line))
  fcnargname=""
  for farg in "${fcnarglist[@]}";do
    farg=${farg//"\""}
    if [[ "$farg" == "outfile="* ]];then
      fcnargname=$farg
      fcnargname=${fcnargname//"outfile="}
      fcnargname=${fcnargname//".root"}
      break
    fi
  done
  theOutdir="${OUTDIR}/${FCN}/${fcnargname}"
  mkdir -p $theOutdir
  ln -sf ${PWD}/${OUTDIR}/${TARFILE} ${PWD}/${theOutdir}/

  submitJHUGenSubmitterGenericJob.sh "$SCRIPTNAME" "$FCN" "$line" "$QUEUE" "$theOutdir"
done < "$INFILE"
