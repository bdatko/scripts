#!/bin/bash
echo "What is your file name?"; read filein
filemaxforce="maxforce.txt"
rm $filemaxforce
filemaxdisplace="maxdisplacement.txt"
rm $filemaxdisplace
grep "Maximum Force" $filein | awk '{print $3}' > $filemaxforce
grep "Maximum Displacement" $filein | awk '{print $3}' > $filemaxdisplace
