#!/bin/bash
# PROGRAM random_odd
#
# random_odd $numberRandomNum $numberDigits $randomfile
#
# Purpose:
#   Randomly generate a number check to see if it's odd, if odd store the
#   value until equal the length desired, numberDigits. Continue generating
#   numbers until the numbers generated equal the desired ammount,
#   numberRandomNum. Store all random numbers in a file named randomfile.
#
# Record of revisions:
#       Date        Programmer      Description of change
#       ====        ==========      =====================
#    13-May-2015    B. D. Datko     Original Code
#
# Declare the variables used in this shell program:
#   INTERGER :: numberRandomNum   !local variable, interger value of the
#                                 !number of desired random numbers
#   INTERGER :: numberDigits      !local variable, interger value of the
#                                 !number of digits per random number
#   CHARACTER :: randomFile       !local variable, character string of the
#                                 !name of the file to store all random
#                                 !numbers generated
#   INTERGER :: length            !local variable, interger value of the
#                                 !current length of the random number
#   INTERGER :: COUNT             !local variable, interger value of the
#                                 !current number of random seeds generated
#   CHARACTER :: dummy            !local variable, character string to hold
#                                 !intermediate random numbers
#
###############################################################################

random_odd ()
{
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

random_odd 2 5 random.txt
echo cat random.txt:
cat random.txt
