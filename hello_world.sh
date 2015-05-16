#!/bin/bash
echo `date`
echo Hello World!
#qstat
#/opt/gridengine/bin/linux-x64/qstat
#export PATH=/opt/gridengine/bin/linux-x64:$PATH
#qstat

nsub=10
numsub=2
echo "next nsub=$(( $nsub-$numsub ))" 
QLIMIT=1
if (( QLIMIT == 1 )); then
    echo QLIMIT = 1
else
    echo QLIMIT != 1
fi

#ls this_file_does_not_exist.txt >> test_stderr.txt 2>&1 || >> test_stderr.txt 2>&1 echo foooooosh

