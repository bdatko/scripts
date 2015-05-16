#!/bin/bash
# PROGRAM test_ifinterger
#
# test_ifinterger $numtest
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
#                           !match negative intergeres
#   INTERGER :: numtest     !local variable, used as the agrument of the
#                           !program
#   CHARACTER :: zero_test  !local variable, used to determine if the zero
#                           !test is required
# Notes:
#   -regular expression re matches the flowing:
#       * "-?" match zero or one of the character '-' (dash)
#       * "^[0-9]+?" match exactly numbers with optional one or more
#         repetitions of numbers
###############################################################################


test_ifinterger ()
{
    local re='-?^[0-9]+?$'

    local numtest=$1

    local zero_test=$2

    # [ ! EXPR ] True if EXPR is false
    # "=~" compares $numtest to extended regular expression
    # string comparision
    if ! [[ $numtest =~ $re ]]; then
        echo Sorry your input of $numtest, is either not a number or negative,\
        enter an interger value greater than zero >&2
        exit 1
    fi

    if [[ $2 == "no" ]]; then
        echo > /dev/null 2>&1
    else
        if [[ $numtest -eq 0 ]]; then
            echo Sorry your inpput of $numtest, is zero please enter value greater\
            than zero >&2
            exit 1
        fi
    fi
}
