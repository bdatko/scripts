#!/bin/bash

test_ans ()
{
    local response=$1

    if [[ $1 =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo TRUE
    else
        echo FALSE
    fi
}

#test_ans y
test_ans no
#test_ans YES
