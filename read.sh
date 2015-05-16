echo "What is your VENUS output file name?"; read filenameoutput
echo "How many atoms does the system have?"; read atomnumber
echo "This script will calculate the distance between two atoms ireating over the whole time."
echo "The script needs to know which two atoms to calculate the distance."
echo "What are the pair of atoms you to calculate the distance between (please put a single space between the two atoms numbers)?"; read atom1 atom2
echo "--------------------"
prefix=$(echo $filenameoutput | sed 's/\./ /' | awk '{print $1}')
suffix=$(echo $filenameoutput | sed 's/\./ /' | awk '{print $2}')
Q_P_file="Q_P_file_$prefix.txt"
rm $Q_P_file
Q_P_dummy="Q_P_dummy.txt"
grep -A "$atomnumber" "                 Q               " "$filenameoutput" >> $Q_P_dummy
sed -e '/Q/d' -e '/--/d' "$Q_P_dummy" >> $Q_P_file
rm $Q_P_dummy
Total_Energy_file="Total_Energy_$prefix.txt"
rm $Total_Energy_file
grep "TOTAL ENERGY:" "$filenameoutput" >> $Total_Energy_file
PE_KE_file="PE_KE_$prefix.txt"
rm $PE_KE_file
grep "POTENTIAL ENERGY:" "$filenameoutput" >> $PE_KE_file
Potential_Energy_file="Potential_Energy_$prefix.txt"
rm $Potential_Energy_file
Kinetic_Energy_file="Kinetic_Energy_$prefix.txt"
rm $Kinetic_Energy_file
Time_file="Time_step_$prefix.txt"
rm $Time_file
grep "TIME:" "$filenameoutput" >> $Time_file
filename="convergence_$prefix.txt"
rm $filename
distfile="distance_atom$atom1-atom$atom2-$prefix.txt"
rm $distfile
energyfile="total_energy_$prefix.txt"
rm $energyfile
echo "Distance" "Total_Energy" "Potential_Energy" "Time" >> $filename
numbersteps=$(grep -c "THE CYCLE COUNT IS:" $filenameoutput)
for ((i=$atom1, j=$atom2, k=1; k <= $numbersteps ; i=i+$atomnumber, j=j+$atomnumber, k++))
do
 atom1_x=$(sed -n "$i"'p' "$Q_P_file" | awk '{print $1}')
 atom1_y=$(sed -n "$i"'p' "$Q_P_file" | awk '{print $2}')
 atom1_z=$(sed -n "$i"'p' "$Q_P_file" | awk '{print $3}')
 distance=$(sed -n "$j"'p' "$Q_P_file" | awk -v a="$atom1_x" -v b="$atom1_y" -v c="$atom1_z" '{print sqrt(($1 - a)^2 + ($2 - b)^2 + ($3 - c)^2)}')
 total_energy=$(sed -n "$k"'p' "$Total_Energy_file" | awk '{print $3}')
 time_step=$(sed -n "$k"'p' "$Time_file" | awk '{print $7}') 
 potential_energy=$(sed -n "$k"'p' "$PE_KE_file" | awk '{print $6}')
 kinetic_energy=$(sed -n "$k"'p' "$PE_KE_file" | awk '{print $3}') 
 echo "$distance" >> $distfile
 echo "$total_energy" >> $energyfile
 echo "$kinetic_energy" >> $Kinetic_Energy_file
 echo "$potential_energy" >> $Potential_Energy_file
 echo "$distance" "$total_energy" "$potential_energy" "$time_step" >> $filename
done
echo "Files created:" "$Q_P_file" "$Total_Energy_file" "$filename" "$distfile" "$energyfile" "$Potential_Energy_file" "$Kinetic_Energy_file" "$Time_file" "$PE_KE_file"
echo "Job Done"           
