#!/bin/bash -l
# SHELL SCRIPT qcron.sh
#
# Purpose:
#   The purpose of this shell script is to automate the 
#   submission of jobs to the PBS/SGE queue scheduler. 
#   The script determines how many jobs are currently running, 
#   how many slots are open in the queue, how many jobs need to be 
#   submitted and determines how many jobs to submit based on the 
#   information obtained. The jobs are submitted with job arrays, 
#   qsub -t. The shell script is ran with crontab 
#   every 15 minutes to determine if jobs can be submitted. 
#   Events are logged within a log file, qsublogfile.txt
#
# Record of revisions:
#       Date        Programmer      Description of change
#       ====        ==========      =====================
#    15-Apr-2015    B. D. Datko     Original Code
#
# Declare the variables used in this shell script
#   CHARACTER :: datesub        !Stdout from bash date
#   CHARACTER :: NSUB           !Name of the text file containing single integer with 
#                               ! original number of jobs
#   CHARACTER :: SSUB           !Name of the text file containing single integer of the
#                               ! indexed start number
#   CHARACTER :: LOGFILE        !Name of the text file of the log
#   CHARACTER :: QLIMITFILE     !Name of the text file containing single integer of the
#                               ! queue limit
#   CHARACTER :: SUBMITDIR      !Path to the directory containing the jobs to submit
#   CHARACTER :: SUBMITFILE     !Name of the PBS/SGE submit file
#   INTEGER :: QLIMIT           !Integer value of the queue limit
#   INTEGER :: NUMJOBS          !Integer value of the number of jobs
#   INTEGER :: STARTSUB         !Integer value of the starting index of jobs
#   INTEGER :: JOBCOUNT         !Integer value of the number of jobs currently running
#   INTEGER :: QSPACE           !Integer value of the open queue slots
#   INTEGER :: NUMJOBSLEFT      !Integer value of the number of jobs left to be
#                               ! submitted
#   INTEGER :: NUMSUBMISSIONS   !Integer value of the number of jobs to be
#                               ! submitted
#   INTEGER :: ENDSUB           !Integer value of the ending index of jobs
#
# Notes:
#  need nsub.txt and ssub.txt within the SUBMITDIR
#  path of the SUBMITFILE needs to be given
#  PATH needs to given to qstat and qsub cmd

source /opt/gridengine
datsub=$(echo `date`)
NSUB=nsub.txt
SSUB=ssub.txt
LOGFILE=qsublog.txt
QLIMITFILE=qlimit.txt

# add path to qsub and qstat
export PATH=/opt/gridengine/bin/linux-x64:$PATH

# edit to cd to directory with all variables set
SUBMITDIR=/home/bdatko/tests/sge_venus_test/qcron_conditional_5

# edit to name of sge/pbs submit file
SUBMITFILE=criegee_sub_draft_1.sge

# cd to the submit dir
cd $SUBMITDIR 

echo "===============================" >> $LOGFILE
echo $datsub >> $LOGFILE
echo "" >> $LOGFILE

# define user vars
read QLIMIT < $QLIMITFILE
read NUMJOBS < $NSUB
read STARTSUB < $SSUB
JOBCOUNT=$( qstat -t | grep 'bdatko' -c)

# Compute the number of open q slots
QSPACE=$(echo "$QLIMIT-$JOBCOUNT"|bc)

# echo user defined vars to logfile
echo "PATH=$PATH" >> $LOGFILE
echo "" >> $LOGFILE
echo "SUBMITDIR=$SUBMITDIR" >> $LOGFILE
echo "SUBMITFILE=$SUBMITFILE" >> $LOGFILE
echo "NUMJOBS=$NUMJOBS" >> $LOGFILE
echo "STARTSUB=$STARTSUB" >> $LOGFILE
echo "QSPACE=$QSPACE" >> $LOGFILE
echo "JOBCOUNT=$JOBCOUNT" >> $LOGFILE
echo "QLIMIT=$QLIMIT" >> $LOGFILE
echo "" >> $LOGFILE
echo "The number of jobs running is: ${JOBCOUNT}" >> $LOGFILE
echo "The queue limit for jobs running is: ${QLIMIT}" >> $LOGFILE

# Conditional #1
# check for open q, true => exit, false => move on
if (( QSPACE <= 0 ))
then
   echo "" >> $LOGFILE
   echo "QSPACE <= 0, Too many jobs running. No new submissions" >> $LOGFILE
   echo "===============================" >> $LOGFILE
   echo "" >> $LOGFILE
   exit
fi

# update the log for possible submissions and number of available jobs
echo "" >> $LOGFILE
echo "The number of jobs possible to submit is: ${QSPACE}" >> $LOGFILE
echo "The number of jobs available to submit is: ${NUMJOBS}" >> $LOGFILE

# Conditional #2
# check number of jobs, true => no more jobs exit, false => move on
if (( NUMJOBS <= 0 ))
then
   echo "#*/13 * * * * /home/bdatko/scripts/foo.sh" | crontab -
   echo "" >> $LOGFILE
   echo "NUMJOBS <= 0, No more jobs available, no new submissions" >> $LOGFILE
   echo "Crontab for qcron.sh deleted" >> $LOGFILE
   echo "===============================" >> $LOGFILE
   echo "" >> $LOGFILE
   exit
fi

# Compute the number of jobs remaining (NUMJOBSLEFT), relative to open slots (QSPACE)
NUMJOBSLEFT=$(echo "$QSPACE-$NUMJOBS" | bc)

# echo user defined vars to logfile
echo "" >> $LOGFILE
echo "NUMJOBSLEFT=$NUMJOBSLEFT" >> $LOGFILE

# If the program hasn't exited yet, then there are jobs remaining and there is space in the queue
#
# The below conditionals do the following:
#
# If value of the queue limit is greater than the number of jobs left to submit
#   then submit remaining jobs starting at the value of STARTSUB and calculate
#   value to end at, ENDSUB
#
# Else submit jobs starting at the value of STARTSUB and calculate value to end at, ENDSUB

# Conditional #3
if (( NUMJOBSLEFT > 0 ))
then
  NUMSUBMISSIONS=${NUMJOBS}
  
  # echo user defined vars to logfile
  echo "" >> $LOGFILE
  echo "NUMSUBMISSIONS=$NUMSUBMISSIONS" >> $LOGFILE
  
  echo "NUMJOBSLEFT > 0, More q space then jobs, submitting: ${NUMSUBMISSIONS} jobs" >> $LOGFILE
  let ENDSUB=$STARTSUB+$NUMSUBMISSIONS-1
  
  # echo user defined vars to logfile
  echo "" >> $LOGFILE
  echo "ENDSUB=$ENDSUB" >> $LOGFILE

  echo "" >> $LOGFILE
  qsub -t ${STARTSUB}-${ENDSUB} $SUBMITDIR/$SUBMITFILE >> $LOGFILE 2>&1 || { echo 'qsub failed' ; exit; } >> $LOGFILE
  echo $(( $ENDSUB + 1 )) > $SSUB
  echo $(( $NUMJOBS - $NUMSUBMISSIONS )) > $NSUB
  
  echo "" >> $LOGFILE
  echo "next STARTSUB=$(( $ENDSUB + 1 ))" >> $LOGFILE
  echo "next NUMJOBS=$(( $NUMJOBS - $NUMSUBMISSIONS ))" >> $LOGFILE
  echo "===============================" >> $LOGFILE
  echo "" >> $LOGFILE
  exit

# Conditional #4
else

  NUMSUBMISSIONS=${QSPACE}
  
  # echo user defined vars to logfile
  echo "" >> $LOGFILE
  echo "NUMSUBMISSIONS=$NUMSUBMISSIONS" >> $LOGFILE

  # Conditional #5
  if (( QLIMIT == 1))
  then
      echo "NUMJOBSLEFT < 0, More q space then jobs, submitting: ${NUMSUBMISSIONS} jobs" >> $LOGFILE
      let ENDSUB=$STARTSUB+1

      # echo user defined vars to logfile
      echo "" >> $LOGFILE
      echo "ENDSUB=$ENDSUB" >> $LOGFILE

      echo "" >> $LOGFILE
      qsub -t ${STARTSUB}-${STARTSUB} $SUBMITDIR/$SUBMITFILE >> $LOGFILE 2>&1 || { echo 'qsub failed' ; exit; } >> $LOGFILE
      echo $(( $STARTSUB + 1 )) > $SSUB
      echo $(( $NUMJOBS - $NUMSUBMISSIONS )) > $NSUB

      echo "" >> $LOGFILE
      echo "next STARTSUB=$(( $STARTSUB + 1 ))" >> $LOGFILE
      echo "next NUMJOBS=$(( $NUMJOBS - $NUMSUBMISSIONS ))" >> $LOGFILE
      echo "===============================" >> $LOGFILE
      echo "" >> $LOGFILE
      exit
  fi

  echo "NUMSUBMISSIONS = NUMJOBSLEFT, More jobs then q space, submitting: ${NUMSUBMISSIONS} jobs" >> $LOGFILE
  let ENDSUB=$STARTSUB+$NUMSUBMISSIONS-1
  
  # echo user defined vars to logfile
  echo "" >> $LOGFILE
  echo "ENDSUB=$ENDSUB" >> $LOGFILE
  
  echo "" >> $LOGFILE
  qsub -t ${STARTSUB}-${ENDSUB} $SUBMITDIR/$SUBMITFILE >> $LOGFILE 2>&1 || { echo 'qsub failed' ; exit; } >> $LOGFILE
  echo $(( $ENDSUB + 1 )) > $SSUB
  echo $(( $NUMJOBS - $NUMSUBMISSIONS )) > $NSUB
  
  echo "" >> $LOGFILE
  echo "next STARTSUB=$(( $ENDSUB + 1 ))" >> $LOGFILE
  echo "next NUMJOBS=$(( $NUMJOBS - $NUMSUBMISSIONS ))" >>$LOGFILE
  echo "===============================" >> $LOGFILE
  echo "" >> $LOGFILE
fi
exit
