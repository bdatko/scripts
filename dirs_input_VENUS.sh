#!/bin/bash
#The VENUS code requires a random seed (ISEED) with a value between 1 and 2^{31} - 1 where the last integer must be odd. 
#Large values containing odd numbers are better.
#The program generates the value ISEED with user inputs of how many ISEED numbers desired and how many odd integers for each number.
#With all the numbers generated the file takes a VENUS input file containing the tag NEED_RANDOM_NUM_HERE and creates a new input file replacing the tag
#with the freshly made ISEED.
#X new input files are created where X is the number of desired input files.
echo How many input files do you want? This value equals the number of random numbers generated; read oddnumrandom
echo How many integers do you want for each random number?; read numdig
echo What number do you want to start at for your directories?; read startnumdir
echo What is the name of your NWChem input file?; read nwchemfile
echo What is the name of your pbs sumbit file?; read pbsfile
echo What is the name of your VENUS inpurt file?; read inputfile
echo Before I start, is the tag NEED_RANDOM_NUM_HERE placed within your VENUS input file named $inputfile? '(yes/no)'; read ans
ans=$(echo $ans | awk '{print tolower($0)}')
if [ "$ans" == y ]; then
 echo ""
 echo Perfect! One more question . . . 
 echo ""
elif [ "$ans" == yes ]; then
 echo ""
 echo Perfect! One more question . . .
 echo ""
else
 echo ""
 echo Sorry you should make sure to have NEED_RANDOM_NUM_HERE in file $inputfile before we start
 echo ""
 exit
fi
echo Is the tag JOBNAME placed within your pbs submit file name $pbsfile? '(yes/no)'; read ans
ans=$(echo $ans | awk '{print tolower($0)}')
if [ "$ans" == y ]; then
 echo ""
 echo Perfect, now we can start.
 echo ""
elif [ "$ans" == yes ]; then
 echo ""
 echo Perfect, now we can start.
 echo ""
else
 echo ""
 echo Sorry you should make sure to have JOBNAME in file $pbsfile before we start
 echo ""
 exit
fi 
prefix=$(echo $inputfile | sed 's/\./ /' | awk '{print $1}') 
suffix=$(echo $inputfile | sed 's/\./ /' | awk '{print $2}')
inputname="inputfile_name"
rm $inputname
echo ----------------------
echo Starting program . . .
echo "" 
randfile="rand.txt"
rm $randfile
dummy="dummy.txt" #dummy is dummy file only holding one random number at a time
length=0
COUNT=0
while [ "$COUNT" -lt "$oddnumrandom" ]; do
 shuf -i 1-9 -n 1 | awk '{ if (($1 % 2) !=0) printf $1 }' >> $dummy #printf adds everything to the same line
 length=$(sed -n 1p $dummy | awk '{print length}') #the sed cmd prints the first line which awk counts the length
 if [ -z "$length" ]; then #protects aginst length = null
  length=0
 fi
 if [ "$length" -ge "$numdig" ]; then
  randnum=$(sed -n 1p $dummy)
  echo $randnum >> $randfile
  COUNT=$(sed -n '$=' $randfile) #counts the number of lines in the file
  length=0
  rm $dummy
 fi
done
if [ "$startnumdir" == 1 ]; then
 for (( i=1; i <= "$oddnumrandom"; i++ )); do
  cp $inputfile "$prefix"_$i."$suffix"
  num=$(sed -n "$i"p $randfile)
  sed -i "s/NEED_RANDOM_NUM_HERE/$num/" "$prefix"_$i."$suffix"
  echo "$prefix"_$i."$suffix" >> $inputname
  mkdir trial"$i"
  mv "$prefix"_$i."$suffix" trial"$i"
  cp $nwchemfile trial"$i"
  cp $pbsfile "$prefix"_$i.pbs 
  sed -i "s/JOBNAME/Criegee_mpi_t"$i"/" "$prefix"_$i.pbs
  sed -i "s/VENUS_INPUT/"$prefix"_$i."$suffix"/" "$prefix"_$i.pbs
  sed -i "s/OUTPUT/"$prefix"_$i.out/" "$prefix"_$i.pbs
  mv "$prefix"_$i.pbs trial"$i"
 done
else
 endnumdir=$(($oddnumrandom + $startnumdir - 1))
 echo The number the dir will start at: $startnumdir
 echo The number the dir will end at: $endnumdir
 for (( i=$startnumdir, j=1; i <= "$endnumdir"; i++, j++ )); do
  cp $inputfile "$prefix"_$i."$suffix"
  num=$(sed -n "$j"p $randfile)
  sed -i "s/NEED_RANDOM_NUM_HERE/$num/" "$prefix"_$i."$suffix"
  echo "$prefix"_$i."$suffix" >> $inputname
  mkdir trial"$i"
  mv "$prefix"_$i."$suffix" trial"$i"
  cp $nwchemfile trial"$i"
  cp $pbsfile "$prefix"_$i.pbs
  sed -i "s/JOBNAME/Criegee_mpi_t"$i"/" "$prefix"_$i.pbs
  sed -i "s/VENUS_INPUT/"$prefix"_$i."$suffix"/" "$prefix"_$i.pbs
  sed -i "s/OUTPUT/"$prefix"_$i.out/" "$prefix"_$i.pbs
  mv "$prefix"_$i.pbs trial"$i"
 done
fi
echo Job Done.
echo ---------------------- 
echo Files created: $randfile, $inputname, "$prefix"_1 through "$oddnumrandom"."$suffix" and "$prefix"_1 through "$oddnumrandom".pbs
echo ""
