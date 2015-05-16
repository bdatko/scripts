#!/bin/bash
qsub -t 1-5 << EOF
#!/bin/bash
#$ -j y
#$ -S /bin/bash
#$ -N serial
#$ -o $JOB_NAME.o$JOB_ID
#$ -e $JOB_NAME.e$JOB_ID
#$ -q normal.q
#$ -l h_rt=00:00:05
#$ -cwd 

echo Start: `date`
echo $JOB_NAME
echo $HOSTNAME
echo $JOB_ID
echo "This is the working dir:" $SGE_O_WORKDIR
echo End:  `date`

EOF
