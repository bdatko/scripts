#!/bin/bash
# PROGRAM test_fileexist
#
# test_fileexist $file
#
# Purpose:
#   To test if the file named file, passed as the agrument file, exist and
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
###############################################################################

test_fileexist ()
{
    local cwd=`pwd`
    
    local file=$1
    
    local file_type=$2

    if [ ! -f $cwd/$file ]; then
        echo Your $file_type, named $file, was not found in the current\
        working directory >&2
        exit 1
    fi
}
