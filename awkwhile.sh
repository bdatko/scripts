awk '{ i = 1
       while (i <= 3) {
           print $i
           i++
       }
}' foo.txt

cat foo.txt | awk '{ i = 1 
	while (i <= 3) {print $i i++ }}'
