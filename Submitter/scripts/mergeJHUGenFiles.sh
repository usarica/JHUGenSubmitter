#!/bin/bash

chkdir=$1
let skipdone=0
if [[ "$2" != "" ]];then
  let skipdone=$2
fi

for f in $(find $chkdir -name "*.tar"); do
  d=${f%/*}
  ff=${f##*/}
  ffmain=${ff//.tar/}

  if [[ $skipdone -eq 1 ]] && [[ -s ${d}/${ffmain}.lhe ]];then
    continue
  fi

  cd $d
  echo "=========="
  echo "Processing $f"
  echo "=========="
  tar xf $ff
  MergeLHEFiles ${ffmain}*.lhe outfile=tmp.lhe
  rm ${ffmain}*.lhe
  mv tmp.lhe ${ffmain}.lhe

  cd - &> /dev/null
done
