#!/bin/bash
# PROGRAM VENUS_input.sh
#
# VENUs_input.sh
#
# Purpose:
#   The purpose of this program is to create N number of input files for
#   VENUS NWChem software. The input files requires a random seed (ISEED) with
#   a value between 1 and 2**{31}-1 where the last integer must be odd. Large
#   values containing odd numbers are better. The script generates the value
#   ISEED with user prompts of how many files are desired, how many integers
#   for each ISEED and what number to start indexing the input files. All the
#   files are created in the current working directory the shell script was
#   called.
#
# Record of revisions:
#       Date        Programmer      Description of change
#       ====        ==========      =====================
#    17-Apr-2015    B. D. Datko     Original Code
#    13-Apr-2015    B. D. Datko     Updated to moulder format
#
# Declare the variables used in this shell script
#   INTEGER :: oddnumrandom         !Integer value of the number of random
#                                   !numbers desired
#   INTEGER :: numdig               !Integer value of the number of digits
#                                   !per random number generated
#   INTEGER :: startnum             !Integer value of the starting index
#                                   !number
#   CHARACTER :: nwchemfile         !Name of the input file used by NWChem
#   CHAEACTER :: inputfile          !Name of the input file used by VENUS
#   CHARACTER :: inputfile_prefix   !Prefix name of the VENUS input file
#   CHARACTER :: inputfile_suffix   !Suffix name of the VENUS input file
#   CHARACTER :: nwchemfile_prefix  !Prefix name of the NWChem input file
#   CHARACTER :: nwchemfile_prefix  !Suffix name of the NWChem input file
#   CHARACTER :: randfile           !Name of the file, random.txt, which
#                                   !contains all the random numbers generated
#
# Notes:
#   -Script requires the VENUS input file to be annotated in a particular way.
#   Where the tag NEED_RANDOM_NUM_HERE needs to be placed within the VENUS 
#   input file on the line respected ISEED line.
#   -Script requires the VENUS input file to be annotated as such:
#       * Tag NEED_INDEX_NUM_HERE needs to be placed within the name of the
#         NWChem file that VENUS is reading, at the beginning of the VENUS 
#         input file
#       * Tag NEED_RANDOM_NUM_HERE needs to be placed within the VENUS input
#         file on the respected line for ISEED value
###############################################################################


# Define functions used throughout the code
test_ifinteger ()
{
    # PROGRAM test_ifinteger
    #
    # test_ifinteger $numtest
    #
    # Purpose:
    #   To test if the argument numtest is either a negative integer or equal
    #   to zero. If both false the program will exit with status of 1. Can be
    #   skip the equal to zero test if the program is passed with the string
    #   "no"
    #
    # Record of revisions:
    #       Date        Programmer      Description of change
    #       ====        ==========      =====================
    #    12-May-2015    B. D. Datko     Original Code
    #
    # Declare the variables used in this shell program:
    #   CHARACTER :: re         !local variable, used for regular expression to
    #                           !match negative integers
    #   INTEGER :: numtest      !local variable, used as the argument of the
    #                           !program
    #   CHARACTER :: zero_test  !local variable, used to determine if the zero
    #                           !test is required
    # Notes:
    #   -regular expression re matches the flowing:
    #       * "-?" match zero or one of the character '-' (dash)
    #       * "^[0-9]+?" match exactly numbers with optional one or more
    #         repetitions of numbers
    ###########################################################################                           

    local re='-?^[0-9]+?$'

    local numtest=$1

    local zero_test=$2

    # [ ! EXPR ] True if EXPR is false
    # "=~" compares $numtest to extended regular expression
    # string comparison
    if ! [[ $numtest =~ $re ]]; then
        echo Sorry your input of $numtest, is either not a number or negative,\
        enter an integer value greater than zero 1>&2
        exit 1
    fi

    if [[ $2 == "no" ]]; then
        echo > /dev/null 2>&1
    else
        if [[ $numtest -eq 0 ]]; then
            echo Sorry your inpput of $numtest, is zero please enter value greater\
            than zero 1>&2
            exit 1
        fi
    fi
}

test_fileexist ()
{
    # PROGRAM test_fileexist
    #
    # test_fileexist $file
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

test_response ()
{
    # PROGRAM test_response
    #
    # test_response $response $filename $tag
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

random_odd ()
{
    # PROGRAM random_odd
    #
    # random_odd $numberRandomNum $numberDigits $randomfile
    #
    # Purpose:
    #   Randomly generate a number check to see if it's odd, if odd store the
    #   value until equal the length desired, numberDigits. Continue generating
    #   numbers until the numbers generated equal the desired amount,
    #   numberRandomNum. Store all random numbers in a file named randomfile.
    #
    # Record of revisions:
    #       Date        Programmer      Description of change
    #       ====        ==========      =====================
    #    13-May-2015    B. D. Datko     Original Code
    #
    # Declare the variables used in this shell program:
    #   INTEGER :: numberRandomNum   !local variable, integer value of the
    #                                 !number of desired random numbers
    #   INTEGER :: numberDigits      !local variable, integer value of the
    #                                 !number of digits per random number
    #   CHARACTER :: randomFile       !local variable, character string of the
    #                                 !name of the file to store all random
    #                                 !numbers generated
    #   INTEGER :: length            !local variable, integer value of the
    #                                 !current length of the random number
    #   INTEGER :: COUNT             !local variable, integer value of the
    #                                 !current number of random seeds generated
    #   CHARACTER :: dummy            !local variable, character string to hold
    #                                 !intermediate random numbers
    #
    ###########################################################################

    local numberRandomNum=$1
    local numberDigits=$2
    local randomFile=$3
    local length=0
    local COUNT=0
    local dummy=""

    while [ "$COUNT" -lt "$numberRandomNum" ]; do

        randomNumber=$(shuf -i 1-9 -n 1)

        if [ $(expr $randomNumber % 2) -ne 0 ]; then

            dummy+=$randomNumber
        fi

        length=${#dummy}

        if [ "$length" -ge "$numberDigits" ]; then

            echo $dummy >> $randomFile

            COUNT=$(sed -n '$=' $randomFile)

            length=0

            dummy=""
        fi
    done
}

# Prompt user for necessary variables

echo How many input files do you want? This value equals the number of random\
numbers generated; read oddnumrandom

# Test oddnumrandom is a positive integer greater than zero exit if false
test_ifinteger $oddnumrandom


echo The number of input files desired is $oddnumrandom
echo ""

echo How many digits do you want for each random number? max is 10; read numdig

# Test numdig is a positive integer greater than zero exit if false
test_ifinteger $numdig

# Check to see if numdig is greater than or equal to 11 if so change
# numdig to the value of 10
if [ $numdig -ge 11 ]; then
    echo ""
    echo Sorry the largest number of digits is 10
    numdig=10
    echo Changing your input to $numdig
else
    echo The number of digits desired is $numdig
    echo ""
fi

echo What number do you want to start at for your input files?; read startnum

# Test startnum is a positive integer greater than zero exit if false 
test_ifinteger $startnum "no"

echo The number to start at is $startnum
echo ""

echo What is the name of your NWChem input file?; read nwchemfile

# Test nwchemfile for existence in the current working directory exit if false
test_fileexist $nwchemfile NWChem_input_file

echo The name of your NWChem input file is $nwchemfile
echo ""

echo What is the name of your VENUS inpurt file?; read inputfile

# Test inputfile for existence in the current working directory exit if false
test_fileexist $inputfile VENUS_input_file

echo The name of your VENUS input file is $inputfile
echo ""

# Check w/ user if the input file is annotated as needed
echo Before I start, is the tag NEED_INDEX_NUM_HERE placed within your VENUS \
input file named $inputfile? '(yes/no)'; read ans

# Test response to above question and double check for the annotations
test_response $ans $inputfile NEED_INDEX_NUM_HERE

# Check w/ user if the input file is annotated as needed
echo Is the tag NEED_RANDOM_NUM_HERE placed within your VENUS input file \
named $inputfile? '(yes/no)'; read ans

# Test response to above question and double check for the annotations
test_response $ans $inputfile NEED_RANDOM_NUM_HERE

#Start the program
echo ----------------------
echo Starting program . . .
echo "" 

# obtain the first half and last half characters of the VENUS and NWChem
# inputfile
inputfile_prefix=$(echo $inputfile | sed 's/\./ /' | awk '{print $1}')
inputfile_suffix=$(echo $inputfile | sed 's/\./ /' | awk '{print $2}')
nwchemfile_prefix=$(echo $nwchemfile | sed 's/\./ /' | awk '{print $1}')
nwchemfile_suffix=$(echo $nwchemfile | sed 's/\./ /' | awk '{print $2}')

# Define the file containing all the random numbers
# If the file already exits assume it was generated from a previous instance of
# this program and delete it create the fresh file
randfile="rand.txt"
rm $randfile  > /dev/null 2>&1 || touch $randfile

random_odd $oddnumrandom $numdig $randfile

# With the random numbers generated start to edit input files and create the
# number of desired input files

# Two cases for index starting at 1 and anything else
if [ "$startnum" == 1 ]; then
    for (( i=1; i <= "$oddnumrandom"; i++ )); do

        # Create a copy of the input files increasing index by one
        cp $inputfile "$inputfile_prefix"_$i."$inputfile_suffix"
        cp $nwchemfile "$nwchemfile_prefix"_$i."$nwchemfile_suffix"

        # Edit the input file with the index and random seed
        sed -i "s/NEED_INDEX_NUM_HERE/$i/" "$inputfile_prefix"_$i."$inputfile_suffix"
        randnum=$(sed -n "$i"p $randfile)
        sed -i "s/NEED_RANDOM_NUM_HERE/$randnum/" "$inputfile_prefix"_$i."$inputfile_suffix"
    done

# Index start number != 1
else
    endnum=$(($oddnumrandom + $startnum - 1))
    for (( i=$startnum, j=1; i <= "$endnum"; i++, j++ )); do

        # Create a copy of the input files increasing index by one
        cp $inputfile "$inputfile_prefix"_$i."$inputfile_suffix"
        cp $nwchemfile "$nwchemfile_prefix"_$i."$nwchemfile_suffix"

        # Edit the input file with the index and random seed
        sed -i "s/NEED_INDEX_NUM_HERE/$i/" "$inputfile_prefix"_$i."$inputfile_suffix"
        randnum=$(sed -n "$j"p $randfile)
        sed -i "s/NEED_RANDOM_NUM_HERE/$randnum/" "$inputfile_prefix"_$i."$inputfile_suffix"
    done
fi

# Print to screen the program has reached the end
echo Job Done.
echo ---------------------- 

if [ "$startnum" == 1 ]; then
    echo Files created: $randfile, \
    "$inputfile_prefix"_"$startnum"."$inputfile_suffix" through \
    "$inputfile_prefix"_"$oddnumrandom"."$inputfile_suffix"
    echo Files created: "$nwchemfile_prefix"_"$startnum"."$nwchemfile_suffix" \
    through "$nwchemfile_prefix"_"$oddnumrandom"."$nwchemfile_suffix"
else
    echo Files created: $randfile, \
    "$inputfile_prefix"_"$startnum"."$inputfile_suffix" through \
    "$inputfile_prefix"_"$endnum"."$inputfile_suffix"
    echo Files created: "$nwchemfile_prefix"_"$startnum"."$nwchemfile_suffix" \
    through "$nwchemfile_prefix"_"$endnum"."$nwchemfile_suffix"
fi
echo ""
