#!/bin/bash
# PROGRAM criegee_dissociation.sh
#
# Purpose:
#   The purpose of this program is to determine how many files meet the
#   fragmentation creteria and move the files to a new directory named DIRNAME.
#   Once all files are moved the new submission files will be appended with the
#   fragment's Cartesian position and momentum for another trajectory
#   calculation. The code used a log file to avoid clobbering output files. The
#   program will check for previous time stamps to first before running the
#   various sub functions. If no previous time stamp was found, the sub
#   function goes ahead and excutes.
#
# Record of revisions:
#       Date        Programmer      Description of change
#       ====        ==========      =====================
#    15-June-2015    B. D. Datko     Original Code
#
# Declare the variables used in this shell script
#   CHARACTER :: LOGFILE            !global variable, string name of the 
#                                   !logfile used throughtout the program
#   CHARACTER :: criegee            !global variable, string name of the type
#                                   !of criegee fragment desired for extraction 
#   CHARACTER :: VENUS_INPUTFILE    !global variable, string name of the VENUS
#                                   !inputfile used to make copies and append
#                                   !to the bottom coordinates Qs and Ps
#   CHARACTER :: NWChem_input_file  !global variable, string name of the NWChem
#                                   !inputfile used to make copies
#   CHARACTER :: NPATH2_input       !global variable, string name of the VENUS
#                                   !inputfile used for propene case created
#                                   !for fragments resulting from NPATH=2
#   CHARACTER :: NWChem_input_file_NPATH2   !global varialbe, string name of
#                                   !the NWChem inputfile for fragments
#                                   !resulting from NPATH=2. Used to make
#                                   !copies
#   CHARACTER :: NPATH3_input       !global variable, string name of the VENUS
#                                   !inputfile used for propene case created
#                                   !for fragments resulting from NPATH=3
#   CHARACTER :: NWChem_input_file_NPATH3   !global varialbe, string name of
#                                   !the NWChem inputfile for fragments
#                                   !resulting from NPATH=2. Used to make
#                                   !copies
#   CHARACTER :: ans                !the string of the user's response
#   INTEGER :: FILECOUNT            !global variable, integer value of the
#                                   !number of files that resulted in a 
#                                   !reaction fragment
#   CHARACTER(100) :: FILELIST      !global variable, array of string names of
#                                   !all the files that resulted in a reaction 
#                                   !fragment
#
# Notes:
#   -Currently the program was design to append Qs and Ps to the bottom of the
#   VENUS Input file. This format is meant for the VENUS calculation NSELT = 0,
#   "calculate a trajectory from coordinates and momenta which are read in."
##############################################################################

# Define Functions used throughout the code

test_response ()
{
    # PROGRAM test_response
    #
    # test_response $response $LOGFILE
    #
    # Purpose:
    #   Check whether the Fragmentation directory needs to be created based on
    #   user response to a yes/no prompt. Add the response to the log file
    #   in order to prevent redundancy.
    #
    # Record of revisions:
    #       Date        Programmer      Description of change
    #       ====        ==========      =====================
    #    12-May-2015    B. D. Datko     Original Code
    #    16-May-2015    B. D. Datko     Changed to look for dir not tag
    #    20-May-2015    B. D. Datko     Changed to update a local log file
    #
    # Declare the variables used in this shell program:
    #   CHARACTER :: __response   !local variable, string of the user's 
    #                             !response
    #   CHARACTER :: DIRNAME      !local variable, string of the Fragmentation
    #                             !dir
    #   CHARACTER :: LOGFILE      !local variable, string of the log file
    #
    # Notes:
    #   -returning variables from a bash function is difficult, this is the
    #   reason for the odd variable name __response and the eval command
    #   -eval command evaluates twice
    #   -idea adopted from the link below (accessed 16-May-2015):
    #   http://www.linuxjournal.com/content/return-values-bash-functions
    #
    ###########################################################################

    local __response=$1

    local LOG=$2

    if [[ $__response =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo
        echo What name to you want to be given to the directory?; read DIRNAME
        echo
        # To be safe, check for DIRNAME
        if [ -d "$DIRNAME" ]; then
            echo The directory $DIRNAME already exist, no need to mkdir\
            $DIRNAME.
            echo
            eval $__response="'$DIRNAME'"
        else
            echo Creating directory $DIRNAME . . .
            mkdir $DIRNAME
            echo
            eval $__response="'$DIRNAME'"
        fi

    elif [[ $__response =~ ^([nN][oO]|[nN])$ ]]; then
        echo
        # Need to be told where to put the files
        echo Okay, what is the name of directory you wish to copy the\
        fragmenation files to?; read DIRNAME
        # To be safe, check for DIRNAME
        if  [ -d "$DIRNAME" ]; then
            echo
            eval $__response="'$DIRNAME'"
        else
            echo I checked for the directory $DIRNAME and did not find the \
            directory in your current working directory. I will make the \
            directory $DIRNAME.
            mkdir $DIRNAME
            echo
            eval $__response="'$DIRNAME'"
        fi

    else
        # If not given a yes or no to the prompt, exit
        echo Sorry I need either a yes or no response 2>&1
        exit 1 
    fi
    echo `date` test_response_EXIT=$? >> $LOG 2>&1
}

cp_files ()
{
    # PROGRAM cp_files
    #
    # cp_files $FILECOUNT $DIRNAME $LOGFILE $criegee
    #
    # Purpose:
    #   To copy all the output files that have met the fragmenation criteria
    #   to a seperate directory for further post processing. Once finished
    #   update the log fie in order to prevent redundancy and clobbering of the
    #   output files from additional executions.
    #
    # Record of revisions:
    #       Date        Programmer      Description of change
    #       ====        ==========      =====================
    #    20-May-2015    B. D. Datko     Original Code
    #
    # Declare the variables used in this shell program:
    #   INTEGER :: COUNT          !local variable, integer value of the number
    #                             !of out put files with fragmenation 
    #   CHARACTER :: DIR          !local variable, string of the Fragmentation
    #                             !directory
    #   CHARACTER :: LOG          !local variable, string of the log file
    #   CHARACTER :: opt          !local variable, string of the criegee
    #                             !fragment
    #   CHARACTER(100) :: LIST    !local variable, list of strings of the names
    #                             !of the output files
    #   CHARACTER :: f            !string name of the files within the variable
    #                             !LIST
    #   CHARACTER :: JOBNAME      !local variable, string slice of the job name
    #   CHARACTER :: JOBID        !local variable, string slice of the job id
    #                             !number
    #   CHARACTER :: JOBNUM       !local variable, string slice of the job
    #                             !number
    #
    # Notes:
    #
    ###########################################################################

    local COUNT=$1

    local DIR=$2

    local LOG=$3

    local opt=$4

    if [ "$opt" = "all" ]; then

        # Update the log fro debugging
        echo COUNT=$COUNT >> $LOG 2>&1
        echo DIR=$DIR >> $LOG 2>&1
        echo opt=$opt >> $LOG 2>&1
        echo >> $LOG 2>&1

        ls -l | grep $DIR >> $LOG 2>&1

        echo
        echo Copying fragmentation files to $DIR . . .
        echo

        # iterate over all the output files
        for f in *.out; do

            # Cut the name of the output file to string together the name of
            # the other file names
            local JOBNAME_NUM=$(echo $f | sed 's/\./ /g' | awk '{print $1}')

            local JOBID=$(echo $f | sed 's/\./ /g' | awk '{print $2}')

            local JOBNUM=$(echo $f | sed 's/\./ /g' | awk '{print $3}')

            local JOBNAME=$(echo $f | sed 's/\./ /' | awk '{print $1}' | sed "s/_$JOBNUM//")

            # Update the log for debugging
            echo JOBNAME_NUM=$JOBNAME >> $LOG 2>&1
            echo JOBID=$JOBID >> $LOG 2>&1
            echo JOBNUM=$JOBNUM >> $LOG 2>&1
            echo JOBNAME=$JOBNAME >> $LOG 2>&1
            echo >> $LOG 2>&1

            # Copy the files to the desired directory
            cp $f $DIR >> $LOG 2>&1
        done

        # Update the log for the status from the last command in this sub
        # function
        echo `date` cp_files_EXIT=$? >> $LOG 2>&1

    else
        
        # List of all the output files matching the fragmentation pattern
        local LIST=$(grep -H "==== SUMMARY OF TRAJECTORY ====" *.out | \
        awk '{print $1}' | sed 's/\:/ /')

        # Update the log for debugging
        echo COUNT=$COUNT >> $LOG 2>&1
        echo DIR=$DIR >> $LOG 2>&1
        echo LIST=$LIST >> $LOG 2>&1
        echo >> $LOG 2>&1

        ls -l | grep $DIR >> $LOG 2>&1

        echo
        echo Copying fragmentation files to $DIR . . .
        echo
        
        for f in $LIST; do
            
            # Cut the name of the output file to string together the name of the
            # other file names
            local JOBNAME_NUM=$(echo $f | sed 's/\./ /g' | awk '{print $1}')
            
            local JOBID=$(echo $f | sed 's/\./ /g' | awk '{print $2}')
            
            local JOBNUM=$(echo $f | sed 's/\./ /g' | awk '{print $3}')

            local JOBNAME=$(echo $f | sed 's/\./ /' | awk '{print $1}' | sed "s/_$JOBNUM//")

            # Update the log for debugging
            echo JOBNAME_NUM=$JOBNAME >> $LOG 2>&1
            echo JOBID=$JOBID >> $LOG 2>&1
            echo JOBNUM=$JOBNUM >> $LOG 2>&1
            echo JOBNAME=$JOBNAME >> $LOG 2>&1
            echo >> $LOG 2>&1

            # Copy the files to the desired directory
            cp $f $DIR >> $LOG 2>&1
            cp $JOBNAME_NUM.nw $DIR >> $LOG 2>&1
            cp $JOBNAME_NUM.dt $DIR >> $LOG 2>&1
            cp "$JOBNAME_NUM"_"$JOBID"."$JOBNUM".fort.8 $DIR >> $LOG 2>&1
            cp "$JOBNAME_NUM"_"$JOBID"."$JOBNUM".fort.50 $DIR >> $LOG 2>&1
            cp varnames_"$JOBNAME".o$JOBNUM $DIR >> $LOG 2>&1
        done

       # Update the log for the status from the last command in this sub function
       echo `date` cp_files_EXIT=$? >> $LOG 2>&1
   fi
}

function frag_input()
{
    # PROGRAM frag_input
    #
    # fraq_input $__response $LOGFILE $DIRNAME $VENUS_INPUTFILE $NWCHEMFILE $criegee
    #
    # Purpose:
    #   Read through every file in the list and extract the corresponding
    #   Q(x,y,z) Cartesian positions of the Fragment and the P(x,y,z) Cartesian
    #   momentum. Append the Q(x,y,z) and the P(x,y,z) to the new input file.
    #   Once finished update the log file to prevent clobbering files.
    #
    # Record of revisions:
    #       Date        Programmer      Description of change
    #       ====        ==========      =====================
    #    26-May-2015    B. D. Datko     Original Code
    #
    # Declare the variables used in this shell program:
    #   CHARACTER(100) :: LIST          !local variable, list of strings of the 
    #                                   !names
    #                                   !of the output files
    #   CHARACTER :: __response         !local variable, string of the response
    #                                   !expect a yes or no
    #   CHARACTER :: LOG                !local variable, string of the log file
    #   CHARACTER :: DIR                !local variable, string of the 
    #                                   !Fragmentation directory
    #   CHARACTER :: INPUTFILE          !local variable, string name of the 
    #                                   !VENUS input file to append coordinates
    #   CHARACTER :: NWCHEMFILE         !local variable, string of the NWChem
    #                                   !inputfile
    #   CHARACTER :: local_LOG          !local variable, string of the stdout
    #                                   !of the sub function frag_input
    #   INTEGER :: COUNT                !local variable, used to index the
    #                                   !input files by one
    #   CHARACTER :: INPUTFILE_prefix   !local variable, string of the prefix
    #                                   !of the VENUS inputfile
    #   CHARACTER :: INPUTFILE_suffix   !local variable, string of the suffix
    #                                   !of the VENUS inputfile
    #   CHARACTER :: NWCHEMFILE_prefix  !local variable, string of the prefix
    #                                   !of the NWChem inputfile
    #   CHARACTER :: NWCHEMFILE_suffix  !local variable, string of the suffix
    #                                   !of the NWChem inputfile
    #   INTEGER(100) :: ATOM_LIST       !local variable, array of the atom 
    #                                   !indices of the fragment, obtain from 
    #                                   !appending the variable ATOM#
    #   INTEGER :: NUMATOMS             !local variable, total number of atoms
    #                                   !within the fragment
    #   INTEGER :: ATOM#                !variable, holds the respected atom 
    #                                   !index of the fragment obtain from the 
    #                                   !user
    #   CHARACTER :: f                  !string name of the files within the
    #                                   !variable LIST
    #   INTEGER :: i                    !local variable, number looped over 
    #                                   !with value from 1 to NUMATOMS
    #   CHARACTER :: JOBNAME            !local variable, string slice of the 
    #                                   !job name
    #   CHARACTER :: JOBID              !local variable, string slice of the 
    #                                   !job id number
    #   CHARACTER :: JOBNUM             !local variable, string slice of the 
    #                                   !job number
    #   INTEGER :: num                  !local variable, used to iterate 
    #                                   !through the array values of ATOM_LIST
    #   REAL(3) :: ATOM_Qxyz            !local variable, array of the x, y and 
    #                                   !z coordinate of the respected atom 
    #                                   !within the fragment
    #   REAL(3) :: ATOM_Pxyz            !local variable, array of the x, y and
    #                                   !z momenta of the respected atom within 
    #                                   !the fragment
    #   INTEGER(5) :: ATOM_LIST_NPATH2  !local variable, array of the atom 
    #                                   !indices of the fragment resulting from 
    #                                   !NPATH=2 (this value is hard coded)
    #   INTEGER(5) :: ATOM_LIST_NPATH3  !local variable, array of the atom
    #                                   !indices of the fragment resulting from
    #                                   !NPATH=3 (this value is hard coded)
    #   INTEGER :: NPATH                !local variable, value of the resulting
    #                                   !fragmentation path
    #
    # Below are variable for case = propene:
    #   INTEGER :: COUNT_NPATH2         !local variable, integer value of the
    #                                   !indexing number of NPATH2 files
    #   INTEGER :: COUNT_NPATH3         !local variable, integer value of the 
    #                                   !indexing number of NPATH3 files
    #   CHARACTER :: NPATH2_input_prefix !local variable, string value of the
    #                                   !prefix of VENUS inputfule for NPATH=2
    #   CHARACTER :: NPATH2_input_suffix !local variable, string value of the
    #                                   !suffix of VENUS inputfile for NPATH=2
    #   CHARACTER :: NPATH3_input_prefix !local variable, string value of the
    #                                   !prefix of VENUS inputfile for NPATH=3
    #   CHARACTER :: NPATH3_input_suffix !local variable, string value of the
    #                                   !suffix of VENUS inputfile for NPATH=3 
    #   CHARACTER :: NPATH2_NWChem_prefix !local variable, string value of the
    #                                   !prefix of NWChem inputfile for NPATH=2
    #   CHARACTER :: NPATH2_NWChem_suffix !local variable, string value of the
    #                                   !suffix of NWChem inputfile for NPATH=2
    #   CHARACTER :: NPATH3_NWChem_prefix !local variable, string value of the
    #                                   !prefix of NWChem inputfile for NPATH=3
    #   CHARACTER :: NPATH3_NWChem_suffix !local variable, string value of the
    #                                   !suffix of NWChem inputfile for NPATH=3
    #   INTEGER(8) :: ATOM_LIST_NPATH2  !local variable, for case propene, array 
    #                                   !of the atom indices of the fragment 
    #                                   !resulting from NPATH=2 (this value is
    #                                   !hard coded)
    #   INTEGER(5) :: ATOM_LIST_NPATH3  !local variable, for case propene,
    #                                   !array of the atom indices of the
    #                                   !fragment resulting from NPATH=2 (this
    #                                   !value is hard coded)
    # Notes:
    #   - respone value read into the function (yes or no) tells wheter to ask 
    #   the user for the array of indices or use the hard coded array 
    #   - the function can either obtain the indices of the atom from the user
    #   or have the array be hard coded
    #
    ###########################################################################


    # List of all the output files matching the fragmentation pattern
    local LIST=$(grep -H "==== SUMMARY OF TRAJECTORY ====" *.out | \
    awk '{print $1}' | sed 's/\:/ /')

    #echo
    #echo From within frag_input, line 287 arg 6=$6

    # check the response to the question "Do you want to ask the user for the
    # list of atoms in the fragment?"
    local __response=$1

    local LOG=$2

    local DIR=$3

    local INPUTFILE=$4

    local NWCHEMFILE=$5

    #echo
    #echo From within frag_input, the global variable criegee=$criegee

    # Need to ask, the string simple passes to the function frag_input but the
    # string propene doesn't pass to the function frag_input
    #local criegee_frag=$6

    #echo
    #echo From within frag_input, line 301 arg 6=$6

    #echo
    #echo From within frag_input criegee=$criegee
    #echo

    local local_LOG="frag_input.log"

    echo
    echo What number do you want to start at for your input files?; read startnum

    local COUNT=$startnum

    local INPUTFILE_prefix=$(echo $INPUTFILE | sed 's/\./ /' | awk '{print $1}')
    local INPUTFILE_suffix=$(echo $INPUTFILE | sed 's/\./ /' | awk '{print $2}')
    local NWCHEMFILE_prefix=$(echo $NWCHEMFILE | sed 's/\./ /' | awk '{print $1}')
    local NWCHEMFILE_suffix=$(echo $NWCHEMFILE | sed 's/\./ /' | awk '{print $2}')

    echo
    echo Beginning splice of the fragment "Q(x,y,z)" and "P(x,y,z)" to the new\
    input file . . . 

    if [[ $__response =~ ^([yY][eE][sS]|[yY])$ ]]; then

        # Copy the input file to the Fragmentation directory
        # Change to the Fragmentation directory to create the new files
        cp $INPUTFILE $DIR
        cp $NWCHEMFILE $DIR
        cd $DIR

        # Update the log
        echo >> $local_LOG
        pwd >> $local_LOG
        
        # Currently only does on type of NPATH, if multiple paths are desired
        # and the different NPATHS require different atom indices will need to
        # hard card within the logical statement "$__response = no"

        # Determine the number of atoms in the fragments
        echo How many atoms are within you fragment?; read NUMATOMS
        
        local ATOM_LIST=()

        # Loop over the number of atoms in the fragments to obtain the array of
        # atom indices
        for i in `seq 1 "$NUMATOMS"`; do
            echo 

            # The perl commands just adds the suffix, st, nd, rd or th
            # depending on the number
            echo What is `echo $i | perl -pe 's/1?\d\b/$&.((0,st,nd,rd)[$&]||th)/eg'` \
            atom in your fragment?; read ATOM"$i"
            echo >> $local_LOG 2>&1
            echo ATOM"$i"=$(( ATOM$i )) >> $local_LOG 2>&1

            # Update the array with the atom index
            ATOM_LIST+=($(( ATOM$i )))
        done

        echo >> $local_LOG 2>&1
        echo ATOM_LIST="${ATOM_LIST[@]}" >> $local_LOG 2>&1
        
        for f in $LIST; do
            
            # Cut the name of the output file to string together the name of the
            # other file names
            local JOBNAME=$(echo $f | sed 's/\./ /g' | awk '{print $1}')

            local JOBID=$(echo $f | sed 's/\./ /g' | awk '{print $2}')

            local JOBNUM=$(echo $f | sed 's/\./ /g' | awk '{print $3}')

            # Create a copy of the input file increasing index by one
            cp $INPUTFILE "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix"
            cp $NWCHEMFILE "$NWCHEMFILE_prefix"_$COUNT."$NWCHEMFILE_suffix"
            sed -i "s/NEED_INDEX_NUM_HERE/$COUNT/" "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix"

            # Iterate through the array ATOM_LIST to obtain the respected
            # coordinates
            for num in "${ATOM_LIST[@]}"; do

                # Update the log with values, useful for debugging
                # Log file will be within the directory $DIR
                echo >> $local_LOG 2>&1
                echo num=$num >> $local_LOG 2>&1

                # Splice the Q(x,y,z) from the output file and store the values
                local ATOM_Qxyz=()
                ATOM_Qxyz+=$(grep "==== SUMMARY OF TRAJECTORY ====" -B17 $f |
                sed -n "$num"p | awk '{print $1, $2, $3}')

                # Update the log with values, useful for debugging
                # Log file will be within the $DIR
                echo >> $local_LOG 2>&1
                echo ATOM_Qxyz=$ATOM_Qxyz >> $local_LOG 2>&1

                # Append Q(x,y,z) coordinates to the input file
                echo $ATOM_Qxyz >> "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix"

                echo >> ../$LOG 2>&1
                echo Fragment coordinates taken from $f and moved to input file\
                "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix" >> ../$LOG 2>&1

            done

            for num in "${ATOM_LIST[@]}"; do

                # Update the log with values, useful for debugging
                # Log file will be within the directory $DIR
                echo >> $local_LOG 2>&1
                echo num=$num >> $local_LOG 2>&1

                # Splice the P(x,y,z) from the output file and store the values
                local ATOM_Pxyz=()
                ATOM_Pxyz+=$(grep "==== SUMMARY OF TRAJECTORY ====" -B17 $f |
                sed -n "$num"p | awk '{print $4, $5, $6}')

                # Update the log with values, useful for debugging
                # Log file will be within the $DIR
                echo >> $local_LOG 2>&1
                echo ATOM_Pxyz=$ATOM_Pxyz >> $local_LOG 2>&1

                # Append P(x,y,z) coordinates to the input file
                echo $ATOM_Pxyz >> "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix"

                echo >> ../$LOG 2>&1
                echo Fragment coordinates taken from $f and moved to input \
                file "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix" >> ../$LOG 2>&1

            done

            # Incerment COUNT by one
            ((COUNT++))
        done
    
    elif [[ $__response =~ ^([nN][oO]|[nN])$ ]]; then

        case $criegee in

            "simple")

                #echo
                #echo From within frag_input case simple criegee=$criegee
                #echo

                # Copy the input file to the Fragmentation directory
                # Change to the Fragmentation directory to create the new files
                cp $INPUTFILE $DIR
                cp $NWCHEMFILE $DIR
                cd $DIR

                # Update the log
                echo >> $local_LOG
                pwd >> $local_LOG
            
                # Do not ask user for the array of atom indices of the fragment but
                # hard code them below. Will need to add number of logical
                # statements equal to number of paths and fragment arraies.
        
                local ATOM_LIST_NPATH2=(1 5 6 7 9)

                local ATOM_LIST_NPATH3=(2 3 4 7 8)

                echo >> $local_LOG 2>&1
                echo ATOM_LIST_NPATH2="${ATOM_LIST_NPATH2[@]}" >> $local_LOG 2>&1
                echo >> $local_LOG 2>&1
                echo ATOM_LIST_NPATH3="${ATOM_LIST_NPATH3[@]}" >> $local_LOG 2>&1

                echo >> $local_LOG 2>&1
                echo \
                "===============================================================================" >> $local_LOG

                echo >> $local_LOG 2>&1
                echo Start to iterate through the output files . . . >> $local_LOG 2>&1

                for f in $LIST; do
                    
                    # Cut the name of the output file to string together the name of
                    # the other file names
                    local JOBNAME=$(echo $f | sed 's/\./ /g' | awk '{print $1}')

                    local JOBID=$(echo $f | sed 's/\./ /g' | awk '{print $2}')

                    local JOBNUM=$(echo $f | sed 's/\./ /g' | awk '{print $3}')

                    # Create a copy of the input file increasing index by one
                    cp $INPUTFILE "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix"
                    cp $NWCHEMFILE "$NWCHEMFILE_prefix"_$COUNT."$NWCHEMFILE_suffix"
                    sed -i "s/NEED_INDEX_NUM_HERE/$COUNT/" "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix"
            
                    # Obtain the value for NPATH and check the value to determine the
                    # correct ATOM_LIST to use
                    NPATH=$(grep "REACTION OCCURRED FOR PATH" $f | awk '{print $5}')

                    if [ "$NPATH" -eq 2 ]; then
                    
                        # Update the log to indicate what NPATH is and the current file
                        # in the list
                        echo >> $local_LOG 2>&1
                        echo -------------------- >> $local_LOG 2>&1
                        echo Reading file $f >> $local_LOG 2>&1
                        echo Appending to file "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix" >> $local_LOG 2>&1

                        echo >> $local_LOG 2>&1
                        echo NPATH=$NPATH >> $local_LOG 2>&1

                        # Iterate through the array ATOM_LIST to obtain the respected
                        # coordinates
                        for num in "${ATOM_LIST_NPATH2[@]}"; do
                        
                            # Update the log with values, useful for debugging
                            # Log file will be within the directory $DIR
                            echo >> $local_LOG 2>&1
                            echo num=$num >> $local_LOG 2>&1

                            # Splice the Q(x,y,z) from the output file and store the
                            # values
                            local ATOM_Qxyz=()
                            ATOM_Qxyz+=$(grep "==== SUMMARY OF TRAJECTORY ====" -B17 $f | sed -n "$num"p | awk '{print $1, $2, $3}')

                            # Update the log with values, useful for debugging
                            # Log file will be within the directory $DIR
                            echo >> $local_LOG 2>&1
                            echo ATOM_Qxyz=$ATOM_Qxyz >> $local_LOG 2>&1

                            # Append Q(x,y,z) coordinates to the input file
                            echo $ATOM_Qxyz >> "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix"

                            echo >> ../$LOG 2>&1
                            echo Fragment coordinates taken from $f and moved to input\
                            file "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix">> ../$LOG 2>&1 
                        done
                        
                        for num in "${ATOM_LIST_NPATH2[@]}"; do
                        
                            # Update the log with values, useful for debugging
                            # Log file will be within the directory $DIR
                            echo >> $local_LOG 2>&1
                            echo num=$num >> $local_LOG 2>&1

                            # Splice the P(x,y,z) from the output file and store the values
                            local ATOM_Pxyz=()
                            ATOM_Pxyz+=$(grep "==== SUMMARY OF TRAJECTORY ====" -B17 $f | sed -n "$num"p | awk '{print $4, $5, $6}')

                            # Update the log with values, useful for debugging
                            # Log file will be within the $DIR
                            echo >> $local_LOG 2>&1
                            echo ATOM_Pxyz=$ATOM_Pxyz >> $local_LOG 2>&1

                            # Append P(x,y,z) coordinates to the input file
                            echo $ATOM_Pxyz >> "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix"

                            echo >> ../$LOG 2>&1
                            echo Fragment coordinates taken from $f and moved to input \
                            file "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix" >> ../$LOG 2>&1
                        done
                    
                    elif [ "$NPATH" -eq 3 ]; then
                        
                        # Update the log to indicate what NPATH is and the current file
                        # in the list
                        echo >> $local_LOG 2>&1
                        echo -------------------- >> $local_LOG 2>&1
                        echo Reading file $f >> $local_LOG 2>&1
                        echo Appending to file "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix" >> $local_LOG 2>&1

                        echo >> $local_LOG 2>&1
                        echo NPATH=$NPATH >> $local_LOG 2>&1
                    
                        for num in "${ATOM_LIST_NPATH3[@]}"; do
                        
                            # Update the log with values, useful for debugging
                            # Log file will be within the directory $DIR
                            echo >> $local_LOG 2>&1
                            echo num=$num >> $local_LOG 2>&1

                            # Splice the Q(x,y,z) from the output file and store the
                            # values
                            local ATOM_Qxyz=()
                            ATOM_Qxyz+=$(grep "==== SUMMARY OF TRAJECTORY ====" -B17 $f | sed -n "$num"p | awk '{print $1, $2, $3}')

                            # Update the log with values, useful for debugging
                            # Log file will be within the directory $DIR
                            echo >> $local_LOG 2>&1
                            echo ATOM_Qxyz=$ATOM_Qxyz >> $local_LOG 2>&1

                            # Append Q(x,y,z) coordinates to the input file
                            echo $ATOM_Qxyz >> "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix"

                            echo >> ../$LOG 2>&1
                            echo Fragment coordinates taken from $f and moved to input\
                            file "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix" >> ../$LOG 2>&1
                        done
                        
                        for num in "${ATOM_LIST_NPATH3[@]}"; do
                        
                            # Update the log with values, useful for debugging
                            # Log file will be within the directory $DIR
                            echo >> $local_LOG 2>&1
                            echo num=$num >> $local_LOG 2>&1

                            # Splice the P(x,y,z) from the output file and store the values
                            local ATOM_Pxyz=()
                            ATOM_Pxyz+=$(grep "==== SUMMARY OF TRAJECTORY ====" -B17 $f | sed -n "$num"p | awk '{print $4, $5, $6}')

                            # Update the log with values, useful for debugging
                            # Log file will be within the $DIR
                            echo >> $local_LOG 2>&1
                            echo ATOM_Pxyz=$ATOM_Pxyz >> $local_LOG 2>&1

                            # Append P(x,y,z) coordinates to the input file
                            echo $ATOM_Pxyz >> "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix"

                            echo >> ../$LOG 2>&1
                            echo Fragment coordinates taken from $f and moved to input \
                            file "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix" >> ../$LOG 2>&1
                        done
                    
                    else
                        echo NPATH from the file $f did not match any the coded \
                        conditionals. No coordinates obtained.
                        echo NPATH from the file $f did not match any the coded \
                        conditionals. No coordinates obtained. >> $local_LOG 2>&1
                    fi
                    
                    # Incerment COUNT by one
                    ((COUNT++))
                done ;;

            "propene")
               
                #echo
                #echo From within frag_input case propene criegee=$criegee 
                #echo

                local COUNT_NPATH2=$startnum
                local COUNT_NPATH3=$startnum

                # Copy the input file to the Fragmentation directory
                # Change to the Fragmentation directory to create the new files
                cp $NPATH2_input $DIR
                cp $NPATH2_NWChem $DIR

                cp $NPATH3_input $DIR
                cp $NPATH3_NWChem $DIR

                cd $DIR

                # Update the log
                echo >> $local_LOG
                pwd >> $local_LOG

                # Do not ask user for the array of atom indices of the fragment but
                # hard code them below. Will need to add number of logical
                # statements equal to number of paths and fragment arraies.

                local NPATH2_input_prefix=$(echo $NPATH2_input | sed 's/\./ /' | awk '{print $1}')
                local NPATH2_input_suffix=$(echo $NPATH2_input | sed 's/\./ /' | awk '{print $2}')

                local NPATH3_input_prefix=$(echo $NPATH3_input | sed 's/\./ /' | awk '{print $1}')
                local NPATH3_input_suffix=$(echo $NPATH3_input | sed 's/\./ /' | awk '{print $2}')

                local NPATH2_NWChem_prefix=$(echo $NPATH2_NWChem | sed 's/\./ /' | awk '{print $1}')
                local NPATH2_NWChem_suffix=$(echo $NPATH2_NWChem | sed 's/\./ /' | awk '{print $2}')

                local NPATH3_NWChem_prefix=$(echo $NPATH3_NWChem | sed 's/\./ /' | awk '{print $1}')
                local NPATH3_NWChem_suffix=$(echo $NPATH3_NWChem | sed 's/\./ /' | awk '{print $2}')

                local ATOM_LIST_NPATH2=(1 2 6 7 8 9 10 11)

                local ATOM_LIST_NPATH3=(3 4 5 10 12)

                echo >> $local_LOG 2>&1
                echo ATOM_LIST_NPATH2="${ATOM_LIST_NPATH2[@]}" >> $local_LOG 2>&1
                echo >> $local_LOG 2>&1
                echo ATOM_LIST_NPATH3="${ATOM_LIST_NPATH3[@]}" >> $local_LOG 2>&1

                echo >> $local_LOG 2>&1
                echo \
                "===============================================================================" >> $local_LOG

                echo >> $local_LOG 2>&1
                echo Start to iterate through the output files . . . >> $local_LOG 2>&1

                for f in $LIST; do
                    
                    # Cut the name of the output file to string together the name of
                    # the other file names
                    local JOBNAME=$(echo $f | sed 's/\./ /g' | awk '{print $1}')

                    local JOBID=$(echo $f | sed 's/\./ /g' | awk '{print $2}')

                    local JOBNUM=$(echo $f | sed 's/\./ /g' | awk '{print $3}')

                    # Obtain the value for NPATH and check the value to determine the
                    # correct ATOM_LIST to use
                    NPATH=$(grep "REACTION OCCURRED FOR PATH" $f | awk '{print $5}')

                    if [ "$NPATH" -eq 2 ]; then

                        # Create a copy of the input file increasing index by
                        # one
                        cp $NPATH2_input "$NPATH2_input_prefix"_$COUNT_NPATH2."$NPATH2_input_suffix"
                        cp $NPATH2_NWChem "$NPATH2_NWChem_prefix"_$COUNT_NPATH2."$NPATH2_NWChem_suffix"

                        sed -i "s/NEED_INDEX_NUM_HERE/$COUNT_NPATH2/" "$NPATH2_input_prefix"_$COUNT_NPATH2."$NPATH2_input_suffix"
                    
                        # Update the log to indicate what NPATH is and the current file
                        # in the list
                        echo >> $local_LOG 2>&1
                        echo -------------------- >> $local_LOG 2>&1
                        echo Reading file $f >> $local_LOG 2>&1
                        echo Appending to file "$NPATH2_input_prefix"_$COUNT_NPATH2."$NPATH2_input_suffix" >> $local_LOG 2>&1

                        echo >> $local_LOG 2>&1
                        echo NPATH=$NPATH >> $local_LOG 2>&1

                        # Iterate through the array ATOM_LIST to obtain the respected
                        # coordinates
                        for num in "${ATOM_LIST_NPATH2[@]}"; do
                        
                            # Update the log with values, useful for debugging
                            # Log file will be within the directory $DIR
                            echo >> $local_LOG 2>&1
                            echo num=$num >> $local_LOG 2>&1

                            # Splice the Q(x,y,z) from the output file and store the
                            # values
                            local ATOM_Qxyz=()
                            ATOM_Qxyz+=$(grep "==== SUMMARY OF TRAJECTORY ====" -B20 $f | sed -n "$num"p | awk '{print $1, $2, $3}')

                            # Update the log with values, useful for debugging
                            # Log file will be within the directory $DIR
                            echo >> $local_LOG 2>&1
                            echo ATOM_Qxyz=$ATOM_Qxyz >> $local_LOG 2>&1

                            # Append Q(x,y,z) coordinates to the input file
                            echo $ATOM_Qxyz >> "$NPATH2_input_prefix"_$COUNT_NPATH2."$NPATH2_input_suffix"

                            echo >> ../$LOG 2>&1
                            echo Fragment coordinates taken from $f and moved to input\
                            file "$NPATH2_input_prefix"_$COUNT_NPATH2."$NPATH2_input_suffix" >> ../$LOG 2>&1 
                        done
                        
                        for num in "${ATOM_LIST_NPATH2[@]}"; do
                        
                            # Update the log with values, useful for debugging
                            # Log file will be within the directory $DIR
                            echo >> $local_LOG 2>&1
                            echo num=$num >> $local_LOG 2>&1

                            # Splice the P(x,y,z) from the output file and store the values
                            local ATOM_Pxyz=()
                            ATOM_Pxyz+=$(grep "==== SUMMARY OF TRAJECTORY ====" -B20 $f | sed -n "$num"p | awk '{print $4, $5, $6}')

                            # Update the log with values, useful for debugging
                            # Log file will be within the $DIR
                            echo >> $local_LOG 2>&1
                            echo ATOM_Pxyz=$ATOM_Pxyz >> $local_LOG 2>&1

                            # Append P(x,y,z) coordinates to the input file
                            echo $ATOM_Pxyz >> "$NPATH2_input_prefix"_$COUNT_NPATH2."$NPATH2_input_suffix"

                            echo >> ../$LOG 2>&1
                            echo Fragment coordinates taken from $f and moved to input \
                            file "$NPATH2_input_prefix"_$COUNT_NPATH2."$NPATH2_input_suffix" >> ../$LOG 2>&1
                        done

                        # Incerment COUNT by one
                        ((COUNT_NPATH2++))
                    
                    elif [ "$NPATH" -eq 3 ]; then

                        # Create a copy of the input file increasing index by
                        # one
                        cp $NPATH3_input "$NPATH3_input_prefix"_$COUNT_NPATH3."$NPATH3_input_suffix"
                        cp $NPATH3_NWChem "$NPATH3_NWChem_prefix"_$COUNT_NPATH3."$NPATH3_NWChem_suffix"

                        sed -i "s/NEED_INDEX_NUM_HERE/$COUNT_NPATH3/" "$NPATH3_input_prefix"_$COUNT_NPATH3."$NPATH3_input_suffix"
                        
                        # Update the log to indicate what NPATH is and the current file
                        # in the list
                        echo >> $local_LOG 2>&1
                        echo -------------------- >> $local_LOG 2>&1
                        echo Reading file $f >> $local_LOG 2>&1
                        echo Appending to file "$NPATH2_input_prefix"_$COUNT_NPATH2."$NPATH2_input_suffix" >> $local_LOG 2>&1

                        echo >> $local_LOG 2>&1
                        echo NPATH=$NPATH >> $local_LOG 2>&1
                    
                        for num in "${ATOM_LIST_NPATH3[@]}"; do
                        
                            # Update the log with values, useful for debugging
                            # Log file will be within the directory $DIR
                            echo >> $local_LOG 2>&1
                            echo num=$num >> $local_LOG 2>&1

                            # Splice the Q(x,y,z) from the output file and store the
                            # values
                            local ATOM_Qxyz=()
                            ATOM_Qxyz+=$(grep "==== SUMMARY OF TRAJECTORY ====" -B20 $f | sed -n "$num"p | awk '{print $1, $2, $3}')

                            # Update the log with values, useful for debugging
                            # Log file will be within the directory $DIR
                            echo >> $local_LOG 2>&1
                            echo ATOM_Qxyz=$ATOM_Qxyz >> $local_LOG 2>&1

                            # Append Q(x,y,z) coordinates to the input file
                            echo $ATOM_Qxyz >> "$NPATH3_input_prefix"_$COUNT_NPATH3."$NPATH3_input_suffix"

                            echo >> ../$LOG 2>&1
                            echo Fragment coordinates taken from $f and moved to input\
                            file "$NPATH3_input_prefix"_$COUNT_NPATH3."$NPATH3_input_suffix" >> ../$LOG 2>&1
                        done
                        
                        for num in "${ATOM_LIST_NPATH3[@]}"; do
                        
                            # Update the log with values, useful for debugging
                            # Log file will be within the directory $DIR
                            echo >> $local_LOG 2>&1
                            echo num=$num >> $local_LOG 2>&1

                            # Splice the P(x,y,z) from the output file and store the values
                            local ATOM_Pxyz=()
                            ATOM_Pxyz+=$(grep "==== SUMMARY OF TRAJECTORY ====" -B20 $f | sed -n "$num"p | awk '{print $4, $5, $6}')

                            # Update the log with values, useful for debugging
                            # Log file will be within the $DIR
                            echo >> $local_LOG 2>&1
                            echo ATOM_Pxyz=$ATOM_Pxyz >> $local_LOG 2>&1

                            # Append P(x,y,z) coordinates to the input file
                            echo $ATOM_Pxyz >> "$NPATH3_input_prefix"_$COUNT_NPATH3."$NPATH3_input_suffix"

                            echo >> ../$LOG 2>&1
                            echo Fragment coordinates taken from $f and moved to input \
                            file "$NPATH3_input_prefix"_$COUNT_NPATH3."$NPATH3_input_suffix" >> ../$LOG 2>&1
                        done

                        # Incerment COUNT by one
                        ((COUNT_NPATH3++))

                    
                    else
                        echo NPATH from the file $f did not match any the coded \
                        conditionals. No coordinates obtained.
                        echo NPATH from the file $f did not match any the coded \
                        conditionals. No coordinates obtained. >> $local_LOG 2>&1
                    fi
                    
                done ;;
                
            "all")

                # Copying all Qs and Ps to the new input file
                cp $INPUTFILE $DIR
                cp $NWCHEMFILE $DIR
                cd $DIR

                # Update the log
                echo >> $local_LOG
                pwd >> $local_LOG
                echo >> $local_LOG 2>&1
                echo \
                "===============================================================================" >> $local_LOG

               echo >> $local_LOG 2>&1
               echo Start to iterate through the output files . . . >> $local_LOG 2>&1

               for f in *.out; do
                   
                   # Cut the name of the output file to string together the name of
                   # the other file names
                   local JOBNAME=$(echo $f | sed 's/\./ /g' | awk '{print $1}')

                   local JOBID=$(echo $f | sed 's/\./ /g' | awk '{print $2}')

                   local JOBNUM=$(echo $f | sed 's/\./ /g' | awk '{print $3}')

                   # Create a copy of the input file increasing index by one
                   cp $INPUTFILE "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix"
                   cp $NWCHEMFILE "$NWCHEMFILE_prefix"_$COUNT."$NWCHEMFILE_suffix"
                   sed -i "s/NEED_INDEX_NUM_HERE/$COUNT/" "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix"

                   echo >> $local_LOG 2>&1
                   echo -------------------- >> $local_LOG 2>&1
                   echo Reading file $f >> $local_LOG 2>&1
                   echo Appending to file "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix" >> $local_LOG 2>&1

                   echo >> $local_LOG 2>&1


                   # Iterate through the array ATOM_LIST to obtain the respected
                   # coordinates
                   for num in $(seq 1 $natoms); do
                       
                       # Update the log with values, useful for debugging
                       # Log file will be within the directory $DIR
                       echo >> $local_LOG 2>&1
                       echo num=$num >> $local_LOG 2>&1

                       # Splice the Q(x,y,z) from the output file and store the
                       # values
                       local ATOM_Qxyz=()
                       ATOM_Qxyz+=$(grep "system" -B14 $f | sed -n "$num"p | awk '{print $1, $2, $3}')

                       # Update the log with values, useful for debugging
                       # Log file will be within the directory $DIR
                       echo >> $local_LOG 2>&1
                       echo ATOM_Qxyz=$ATOM_Qxyz >> $local_LOG 2>&1

                       # Append Q(x,y,z) coordinates to the input file
                       echo $ATOM_Qxyz >> "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix"

                       echo >> ../$LOG 2>&1
                       echo Fragment coordinates taken from $f and moved to input\
                       file "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix">> ../$LOG 2>&1
                   done

                   for num in $(seq 1 $natoms); do
                       
                       # Update the log with values, useful for debugging
                       # Log file will be within the directory $DIR
                       echo >> $local_LOG 2>&1
                       echo num=$num >> $local_LOG 2>&1

                       # Splice the P(x,y,z) from the output file and store the values
                       local ATOM_Pxyz=()
                       ATOM_Pxyz+=$(grep "system" -B14 $f | sed -n "$num"p | awk '{print $4, $5, $6}')

                       # Update the log with values, useful for debugging
                       # Log file will be within the $DIR
                       echo >> $local_LOG 2>&1
                       echo ATOM_Pxyz=$ATOM_Pxyz >> $local_LOG 2>&1

                       # Append P(x,y,z) coordinates to the input file
                       echo $ATOM_Pxyz >> "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix"

                       echo >> ../$LOG 2>&1
                       echo Fragment coordinates taken from $f and moved to input \
                       file "$INPUTFILE_prefix"_$COUNT."$INPUTFILE_suffix" >> ../$LOG 2>&1
                   done
               
               done ;;

            *)
                echo No criegee name given. ;;

        esac

    else
        echo Needed a yes or no answer to the question, Do you want to ask \
        the user for the list of atoms in the fragment? Recieved no such \
        response, exiting. 2>&1
        exit 1
    fi

    echo >> $local_LOG 2>&1
    echo \
    "===============================================================================" >> $local_LOG

    # Update the log for the status from the last command in this sub function
    echo >> ../$LOG 2>&1
    echo `date` frag_input_EXIT=$? >> ../$LOG 2>&1

}

test_fileexist ()
{
    # PROGRAM test_fileexist
    #
    # test_fileexist $file $file_type
    #
    # Purpose:
    #   To test if the file named file, passed as the argument file, exist and
    #   is a regular file.
    #
    # Record of revisions:
    #       Date        Programmer      Description of change
    #       ====        ==========      =====================
    #    12-May-2015    B. D. Datko     Original Code
    #
    # Declare the variables used in this shell program:
    #   CHARACTER :: file       !file to test for existence
    #   CHARACTER :: cwd        !the PATH of the current working directory
    #                           !equal to the pwd sto
    #   CHARACTER :: file_type  !type of file (input or output) of file
    #                           !variable
    #
    # Notes:
    #   -bash conditional statement [ -f FILE ]
    #       * True if FILE exists and is a regular file.
    #
    ###########################################################################

    local cwd=`pwd`

    local file=$1

    local file_type=$2

    if [ ! -f $cwd/$file ]; then
        echo Your $file_type, named $file, was not found in the current\
        working directory 1>&2
        exit 1
    fi
}

test_filetag ()
{
    # PROGRAM test_filetag
    #
    # test_filetag $response $filename $tag
    #
    # Purpose:
    #   Check whether the input files have the required tags based on user
    #   response to a yes/no prompt.
    #
    # Record of revisions:
    #       Date        Programmer      Description of change
    #       ====        ==========      =====================
    #    12-May-2015    B. D. Datko     Original Code
    #
    # Declare the variables used in this shell program:
    #   CHARACTER :: response   !the string of the user's response
    #   CHARACTER :: filename   !the string of the file name
    #   CHARACTER :: tag        !unique tag to search for with in filename
    #
    ###########################################################################

    local response=$1

    local filename=$2

    local tag=$3

    if [[ $1 =~ ^([yY][eE][sS]|[yY])$ ]]; then
        # To be safe, Check for necessary tag
        grep "$tag" $filename > /dev/null 2>&1 || { echo Sorry I checked for\
        the tag $tag within $filename and could not find the tag. Please make\
        sure to have the $tag tag within $filename before we start 1>&2 ; exit
        1; }
        echo Perfect!
        echo
    else
        echo ""
        echo Sorry you should make sure to have $tag in file \
        $filename before we start 1>&2
        echo ""
        exit 1
    fi
}

check_logfile()
{
    # PROGRAM check_logfile
    #
    # check_logfile $LOGFILE "sub_function"
    #
    # Purpose:
    #   To check the log file to see if a previous run of the sub_function was
    #   ranned to avoid clobbering any out put files. Depending on the outcome
    #   of the search for a previous run, the program will either run the
    #   sub_function or out put to stdout when the last successful run was. For
    #   either outcome the program will update the log file.
    #
    # Record of revisions:
    #       Date        Programmer      Description of change
    #       ====        ==========      =====================
    #    31-May-2015    B. D. Datko     Original Code
    #
    # Declare the variables used in this shell program:
    #   CHARACTER :: LOG            !local variable, string of the log file
    #   CHARACTER :: sub_function   !local variable, string of the name of the
    #                               !sub function
    #   CHARACTER :: STATUS_DATE    !local variable, string of the date when 
    #                               !the sub_function exited with a status 
    #                               !equal to zero
    #   CHARACTER :: LAST_DIRNAME   !local variable, string of the name of the
    #                               !last directory used to store the out put 
    #                               !files
    #   CHARACTER :: ans            !global variable, string of the user
    #                               !response
    #   INTEGER :: FILECOUNT        !global variable, integer value of the number
    #                               !of out put files with fragmenation 
    #   CHARACTER :: DIRNAME        !local variable, string of the Fragmentation
    #                               !directory
    #   CHARACTER :: __response     !local variable, string of the response
    #                               !expect a yes or no
    #
    #
    # Notes:
    #   - Use of case function to test between the different sub_functions used
    #   within the entire program
    #   - If more sub functions need to be tested aginst a log file, will need
    #   to add more cases with the name of the sub functions
    #
    ###########################################################################

    local LOG=$1

    local sub_function=$2

    # Test to see if the logfie exist
    # Using the logile to avoid clobbering the output files when copying

    if [ -f $LOG ]; then

        case $sub_function in

            "test_response" ) 

                if grep ""$sub_function"_EXIT=0" $LOG > /dev/null ; then

                    # Found a previous log the sub function test_response
                    # Out put to user will not run test_response and update 
                    # the log

                    echo
                    local STATUS_DATE=$(grep ""$sub_function"_EXIT=0" $LOG | cut -d ' ' -f1-5)

                    # Output to stdout there was a previous run
                    echo According to the log file, a fragment directory was \
                    last created successfully on $STATUS_DATE
                    echo No need to create a new directory.
                    local LAST_DIRNAME=$(tac $LOG | grep DIR | \
                    sed 's/\=/ /' | awk '{print $2}')
                    echo The Last directory used to store the files was \
                    $LAST_DIRNAME

                    # DIRNAME should be a global variable
                    DIRNAME=$LAST_DIRNAME
                    
                    # Update the logfiles
                    echo Detected a previous successfull run of $sub_function,\
                    on $STATUS_DATE >> $LOG 2>&1
                    echo Skipping sub function $sub_function >> $LOG 2>&1
                    echo >> $LOG 2>&1
                    echo

                else

                    # Did not find a previous log running the sub function
                    # test_response

                    echo running sub function $sub_function >> $LOG 2>&1

                    # Run the sub function
                    echo Log file checked, there was no record of a previous\
                    run.
                    test_response $ans $LOG

                    # Update the logfile
                    echo end of sub function $sub_function >> $LOG 2>&1
                    echo >> $LOG 2>&1
                fi ;;


            "cp_files" )

                if grep ""$sub_function"_EXIT=0" $LOG > /dev/null ; then

                    # Found a previous log the sub function cp_files
                    # Out to user will not run cp_files and update the log

                    local STATUS_DATE=$(grep ""$sub_function"_EXIT=0" $LOG | cut -d ' ' -f1-5)

                    # Output to stdout there was a previous run
                    echo According to the log file, copying files was \
                    last done successfully on $STATUS_DATE
                    echo No need to do it again.
                    local LAST_DIRNAME=$(tac $LOG | grep DIR | \
                    sed 's/\=/ /' | awk '{print $2}') 
                    echo The Last directory used to store the files was \
                    $LAST_DIRNAME

                    # Update the logfile
                    echo Detected a previous successfull run of cp_files, on \
                    $STATUS_DATE >> $LOG 2>&1
                    echo Skipping sub function $sub_function >> $LOG 2>&1
                    echo >> $LOG 2>&1
                    echo

                else

                    # Did not find a previous log running the sub function
                    # cp_files
                    
                    echo running sub function $sub_function >> $LOG 2>&1

                    # Run the sub function
                    echo Log file checked, there was no record of a previous\
                    run.
                    cp_files $FILECOUNT $DIRNAME $LOG

                    # Update the logfile
                    echo end of sub function $sub_function >> $LOG 2>&1
                    echo >> $LOG 2>&1
                fi ;;

            "frag_input" )

                if grep ""$sub_function"_EXIT=0" $LOG > /dev/null ; then

                    # Found a previous log the sub function fraq_input
                    # Out put to user will not run cp_files and update the log

                    local STATUS_DATE=$(grep ""$sub_function"_EXIT=0" $LOG | cut -d ' ' -f1-5)

                    # Out put to stdout there was a previous run
                    echo According to the log file, splicing Qs and Ps to a \
                    new input file was last done successfully on $STATUS_DATE
                    echo No need to do it again.
                    local LAST_DIRNAME=$(tac $LOG | grep DIR | \
                    sed 's/\=/ /' | awk '{print $2}')
                    echo The Last directory used to store the files was \
                    $LAST_DIRNAME

                    # Update the logfile
                    echo Detected a previous successfull run of $sub_function, on \
                    $STATUS_DATE >> $LOG 2>&1
                    echo Skipping sub function $sub_function >> $LOG 2>&1
                    echo >> $LOG 2>&1
                    echo

                else

                    # Did not find a previous log running the sub function
                    # frag_input

                    echo running sub function $sub_function >> $LOG 2>&1

                    # Run the sub function
                    echo Log file checked, there was no record of a previous\
                    run.

                    #echo
                    #echo From within check_logfile criegee=$criegee
                    #echo
                    frag_input no $LOG $DIRNAME $VENUS_INPUTFILE $NWCHEMFILE $criegee

                    # Update the logfile
                    echo end of sub function $sub_function >> ../$LOG 2>&1
                    echo >> ../$LOG 2>&1
                fi ;;

            * ) 
                echo No sub function name given. ;;
        esac

    else
        # Without the logfile will exit the program
        echo There is no log file. $LOGFILE, no such file 2>&1
        exit 1
    fi
}

#Start the program
echo ----------------------
echo Starting program . . .
echo

# Create a logfile for debugging purposes
LOGFILE=criegee_diss.log

echo LOGFILE=$LOGFILE

# Update the logfile
echo \
"===============================================================================" >> $LOGFILE
echo `date` >> $LOGFILE 2>&1
echo >> $LOGFILE 2>&1
echo Log file for simple_criegee_dissociation.sh >> $LOGFILE 2>&1
echo Env and shell variables print out below. >> $LOGFILE 2>&1
echo >> $LOGFILE 2>&1
echo Starting program ... >> $LOGFILE 2>&1
echo >> $LOGFILE 2>&1

# Ask which criegee fragment to look for
echo
echo Options for criegee fragments:
echo simple - will extract 5 atoms, formaldehyde carbonyl oxide
echo propene - will extract 8 atoms, acetaldehyde oxide
echo all - will extract all Qs and Ps, regardless of fragment
echo
echo "Which criegee fragment do you want to extract?"; read criegee

if [ "$criegee" = "all" ]; then

    echo
    echo "What is the total number of atoms?"; read natoms

    echo
    echo The number of atoms is $natoms

fi

case $criegee in

    "simple")
        echo
        echo Your choice of criegee is $criegee

        # Obtain the name of VENUS input file to copy files to
        echo
        echo What is the name of your VENUS input file, which I will append the \
        fragmenation coordinates to?; read VENUS_INPUTFILE

        echo
        echo VENUS_INPUTFILE=$VENUS_INPUTFILE

        # Test VENUS_INPUTFILE for existence in the current working directory
        # exit if false
        test_fileexist $VENUS_INPUTFILE VENUS_input_file

        # Check w/ user if the VENUS input file is annotated as needed
        echo
        echo Before I start, is the tag NEED_INDEX_NUM_HERE placed within \
        your VENUS input file named $VENUS_INPUTFILE? '(yes/no)'; read ans

        # Test response to above question and double check for the annotations
        test_filetag $ans $VENUS_INPUTFILE NEED_INDEX_NUM_HERE

        # Obtain the name of NWChem input file to copy files
        echo What is the name of your NWChem input file?; read NWCHEMFILE

        # Test NWCHEMFILE for existence in the current working directory exit
        # if false
        test_fileexist $NWCHEMFILE NWChem_input_file

        echo
        echo NWCHEMFILE=$NWCHEMFILE ;;

    "propene")

        echo
        echo Your choice of criegee is $criegee

        # Obtain the name of VENUS input file to copy files to
        echo
        echo What is the name of your VENUS input file for NPATH=2?; read NPATH2_input

        # Test VENUS_INPUTFILE for existence in the current working directory
        # exit if false
        test_fileexist $NPATH2_input VENUS_input_file_NPATH2

        echo
        echo The name of your VENUS inputfile for NPATH=2 is $NPATH2_input

        echo
        echo What is the name of your VENUS input file for NPATH=3?; read NPATH3_input

        # Test VENUS_INPUTFILE for existence in the current working directory
        # exit if false
        test_fileexist $NPATH3_input VENUS_input_file_NPATH3

        echo
        echo The name of your VENUS inputfile for NPATH=2 is $NPATH3_input

        # Check w/ user if the VENUS input file is annotated as needed
        echo
        echo Before I start, is the tag NEED_INDEX_NUM_HERE placed within \
        your VENUS input file named $NPATH2_input? '(yes/no)'; read ans

        # Test response to above question and double check for the annotations
        test_filetag $ans $NPATH2_input NEED_INDEX_NUM_HERE

        # Check w/ user if the VENUS input file is annotated as needed
        echo Before I start, is the tag NEED_INDEX_NUM_HERE placed within \
        your VENUS input file named $NPATH3_input? '(yes/no)'; read ans

        # Test response to above question and double check for the annotations
        test_filetag $ans $NPATH3_input NEED_INDEX_NUM_HERE

        # Obtain the name of NWChem input file to copy files
        echo What is the name of your NWChem input file for NPATH=2?; read NPATH2_NWChem

        # Test NWCHEMFILE for existence in the current working directory exit
        # if false
        test_fileexist $NPATH2_NWChem NWChem_input_file_NPATH2

        echo
        echo NPATH2_NWChem=$NPATH2_NWChem

        # Obtain the name of NWChem input file to copy files
        echo What is the name of your NWChem input file for NPATH=3?; read NPATH3_NWChem

        # Test NWCHEMFILE for existence in the current working directory exit
        # if false
        test_fileexist $NPATH3_NWChem NWChem_input_file_NPATH3

        echo
        echo NPATH3_NWChem=$NPATH3_NWChem ;;

    "all")
        echo
        echo Your choice is $criegee, will extract all resulting Qs ans Ps

        # Obtain the name of VENUS input file to copy files to
        echo
        echo What is the name of your VENUS input file, which I will append the \
        fragmenation coordinates to?; read VENUS_INPUTFILE

        echo
        echo VENUS_INPUTFILE=$VENUS_INPUTFILE

        # Test VENUS_INPUTFILE for existence in the current working directory
        # exit if false
        test_fileexist $VENUS_INPUTFILE VENUS_input_file

        # Check w/ user if the VENUS input file is annotated as needed
        echo
        echo Before I start, is the tag NEED_INDEX_NUM_HERE placed within \
        your VENUS input file named $VENUS_INPUTFILE? '(yes/no)'; read ans

        # Test response to above question and double check for the annotations
        test_filetag $ans $VENUS_INPUTFILE NEED_INDEX_NUM_HERE

        # Obtain the name of NWChem input file to copy files
        echo What is the name of your NWChem input file?; read NWCHEMFILE

        # Test NWCHEMFILE for existence in the current working directory exit
        # if false
        test_fileexist $NWCHEMFILE NWChem_input_file

        echo
        echo NWCHEMFILE=$NWCHEMFILE ;;

    "other")
        echo Sorry, $criegee is not a criegee fragment 2>&1
        exit 1 ;;

    *)
        echo Sorry, $criegee is not a criegee fragment 2>&1
        exit 1 ;;

esac

# Check to see if need to create a new dir
echo
echo Do you need to create the directory, to move the files?; read ans

echo
echo Hold, I will check the log file to ensure I do not clobber any files . . .
sleep 0.15

check_logfile $LOGFILE "test_response"

FILECOUNT=$(grep -H "==== SUMMARY OF TRAJECTORY ====" *.out | wc -l)

FILELIST=$(grep -H "==== SUMMARY OF TRAJECTORY ====" *.out | awk '{print $1}' \
| sed 's/\:/ /')

check_logfile $LOGFILE "cp_files"

check_logfile $LOGFILE "frag_input"

echo \
"===============================================================================" >> ../$LOGFILE
echo >> ../$LOGFILE

echo
echo Job Done.
echo ----------------------
