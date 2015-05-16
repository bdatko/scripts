#!/bin/bash
# script to send simple email 
# email subject
SUBJECT="SET-EMAIL-SUBJECT"
# Email To ?
EMAIL="ben.datko@gmail.com"
# Email text/message
EMAILMESSAGE="$HOME/scripts/emailmessage.txt"
echo "This is an email message test"> $EMAILMESSAGE
echo "This is email text" >>$EMAILMESSAGE
# send an email using /bin/mail
/bin/mailx -s "$SUBJECT" "$EMAIL" < $EMAILMESSAGE
