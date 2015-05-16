#!/bin/bash
echo What are your output files should be 4?; read filename1 filename2 filename3 filename4
molecule1=$(echo $filename1 | sed 's/\./ /' | awk '{print $1}')
molecule2=$(echo $filename2 | sed 's/\./ /' | awk '{print $1}')
molecule3=$(echo $filename1 | sed 's/\./ /' | awk '{print $1}')
molecule4=$(echo $filename1 | sed 's/\./ /' | awk '{print $1}')
suffix=$(echo $filename | sed 's/\./ /' | awk '{print $2}')
echo $molecule1."$suffix"
tac $molecule1."$suffix" | grep -m 1 "Total DFT energy"
tac $molecule2.$suffix | grep -m 1 "Total DFT energy"
tac $molecule3.$suffix | grep -m 1 "Total DFT energy"
tac $molecule4.$suffix | grep -m 1 "Total DFT energy"
