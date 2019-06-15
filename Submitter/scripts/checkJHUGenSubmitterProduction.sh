#!/bin/bash

chkdir=$1
let multiprod=1
if [[ "$2" != "" ]];then
  let multiprod=$2
fi


let nOK=0
let nCOPYFAIL=0
let nFAIL=0
let nFILEDNE=0
let nUNKNOWN=0

cd $chkdir

for d in $(ls ./); do
  if [[ ! -d $d ]];then
    continue
  fi

  let countOK=0
  let dirok=1
  let nsubjobs=0
  for logfilename in $(ls ./$d/Logs | grep -e "log_"); do
    let nsubjobs=$nsubjobs+1

    res=$(grep -e "File generation was successful" $d/Logs/$logfilename)
    res2=$(grep -e "Copied successfully" $d/Logs/$logfilename)

    if [[ ! -z $res ]];then
      if [[ ! -z $res2 ]];then
        res3=$(grep -e "Running: env -i " $d/Logs/$logfilename)
        res3=${res3//*"gsiftp://gftp.t2.ucsd.edu"}
        if [[ -s $res3 ]];then
          echo $d" ran successfully"
          let nOK=$nOK+1
          let countOK=$countOK+1
        else
          echo $d" ran successfully, but the file does not exist!"
          let nFILEDNE=$nFILEDNE+1
          let dirok=0
        fi
      else
        echo $d" file ok but copy failed"
        let nCOPYFAIL=$nCOPYFAIL+1
        let dirok=0
      fi
    elif [ -s $d/Logs/$logfilename ];then
      echo $d" failed"
      let nFAIL=$nFAIL+1
      let dirok=0
    else
      echo $d" status is not yet determined"
      let nUNKNOWN=$nUNKNOWN+1
      let dirok=0
    fi

  done

  if [[ $countOK -gt 0 ]] && [[ $dirok -eq 0 ]];then
    if [[ $multiprod -eq 1 ]];then
      echo $d" has multiple submissions with $countOK / $nsubjobs success rate, but the folder will be treated as if it failed."
    else
      echo $d" has multiple submissions with $countOK / $nsubjobs success rate, but the user specified the folders to be treated as single jobs."
      let dirok=1
    fi
  fi

  if [[ $dirok -eq 1 ]];then
    TARFILE="${d}.tar"
    rm -f $TARFILE
    tar Jcf ${TARFILE} $d --exclude={*.tar}
    if [[ $? -eq 0 ]];then
      echo "- Compressed successfully, so removing the directory"
      rm -rf $d
    fi
  fi

done

cd -

echo "(OK:COPY_FAIL:FILE_DNE:FAIL:UNKNOWN) = (${nOK}:${nCOPYFAIL}:${nFILEDNE}:${nFAIL}:${nUNKNOWN})"
