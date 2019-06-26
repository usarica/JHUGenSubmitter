#!/bin/bash

chkdir=$1

for f in $(find $chkdir -name "*.tar"); do
  d=${f%/*}
  ff=${f##*/}
  ffmain=${ff//.tar/}

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
