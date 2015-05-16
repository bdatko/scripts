#!/bin/bash
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
###############################################################################


test_response ()
{
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
        $filename before we start
        echo ""
        exit
    fi
}


test_response yes h_co2.dt NEED_INDEX_NUM_HERE 
