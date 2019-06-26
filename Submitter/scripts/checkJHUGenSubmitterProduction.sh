#!/bin/bash

chkdir=$1

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

  let dirok=0
  let ncpfail=0
  let nlogfiles=0
  runstring=""
  for logfilename in $(ls ./$d/Logs | grep -e "log_"); do
    if [[ -s ./$d/Logs/$logfilename ]];then
      runstring="$runstring ./$d/Logs/$logfilename"
      let nlogfiles=$nlogfiles+1
    fi
  done
  
  if [[ -z $runstring ]];then
    echo "$d status is unknown."
    let nUNKNOWN=$nUNKNOWN+1
  else
    if [[ $nlogfiles -gt 1 ]];then
      echo "$d has $nlogfiles log files!"
    fi
    runcmd="CheckJHUGenSubmissionLogFile$runstring"
    runoutput=("$(eval $runcmd)")
    for rout in ${runoutput[@]};do
      if [[ "$rout" == *"Failed"* ]];then
        let ncpfail=$ncpfail+1
      fi
    done

    if [[ $ncpfail -gt 0 ]];then
      echo "$d failed."
      let nFAIL=$nFAIL+1
    else
      echo "$d is successful."
      let dirok=1
      let nOK=$nOK+1
    fi
  fi

  if [[ $dirok -eq 1 ]];then
    TARFILE="${d}.tar"
    rm -f $TARFILE
    tar Jcf ${TARFILE} $d --exclude={*.tar}
    if [[ $? -eq 0 ]];then
      echo "- Compressed successfully, so removing the directory"
      rm -rf $d
    else
      echo "- Compression failed!"
      rm -f $TARFILE
    fi
  fi

done

cd -

echo "(OK:COPY_FAIL:FILE_DNE:FAIL:UNKNOWN) = (${nOK}:${nCOPYFAIL}:${nFILEDNE}:${nFAIL}:${nUNKNOWN})"
