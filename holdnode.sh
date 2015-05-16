#!/bin/bash
#
# Reserve a node for an indefinite amount of time
#

qsub << EOF
#!/bin/bash
#$ -R Y
#$ -j y
#$ -S /bin/bash
#$ -N Reserved
#$ -o $JOB_NAME.o$JOB_ID
#$ -q normal.q
#$ -pe fill 12
# change above line to "-pe mpi 24" for two nodes, for example
echo $HOSTNAME

 while true; do sleep 10000; done

EOF
