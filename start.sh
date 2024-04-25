#! /bin/bash
#Author: Mike Deck

# This script will start and prepare all the needed services and the
# environment for a clean upload

# Enter pcap file as first parameter
if [ "$#" -lt 1 ]; then
 echo "Please enter a pcap file as first parameter"
 exit
fi


echo "----- Start of setting up environment -----"
sudo systemctl start elasticsearch.service
sudo systemctl start arkimeviewer.service
sudo systemctl start arkimewise.service

echo WIPE | sudo /opt/arkime/db/db.pl http://localhost:9200 wipe > /dev/null 2>&1
echo "----- Finished with starting all services -----"


# Reading in the pcap file. This must be entered as a argument
echo "----- Starting to read in pcap file -----"
sudo /opt/arkime/bin/capture -r "$1" --copy

#Resetting viewer to prevent unwanted artifacts from previous sessions.
sudo systemctl restart arkimeviewer.service



