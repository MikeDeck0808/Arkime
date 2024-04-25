#! /bin/bash
#Author: Mike Deck
# ---------- enter target file as first parameter ----------
if [ "$#" -lt 1 ]; then
 echo "Please enter a pcap file as first parameter."
 exit
fi




# How many unique sources were received.
echo "---------- Protocols ----------"
echo "Unique TCP sources:"
unique_tcp=$(tcpdump -nr $1 tcp 2>/dev/null | awk -F" " '{print $3}' | awk -F. '{print $1"."$2"."$3"."$4}' | sort | uniq | wc -l)
echo $unique_tcp

echo "Unique UDP sources:"
unique_udp=$(tcpdump -nr $1 udp 2>/dev/null | awk -F" " '{print $3}' | awk -F. '{print $1"."$2"."$3"."$4}' | sort | uniq | wc -l)
echo $unique_udp

echo "Unique ICMP sources:"
unique_icmp=$(tcpdump -nr $1 icmp 2>/dev/null | awk -F" " '{print $3}' | awk -F. '{print $1"."$2"."$3"."$4}' | sort | uniq | wc -l)
echo $unique_icmp
echo ""




# For each of TCP and UDP, what proportion (percentage) of the traffic received in the complete dataset is observed.
echo "---------- Total Sources And Packets ----------"
echo "Total sources of dataset:"
sources=$(tcpdump -nr $1 2>/dev/null | awk -F" " '{print $3}' | awk -F. '{print $1"."$2"."$3"."$4}' | sort | uniq | wc -l)
echo $sources

echo "Total packets of dataset:"
packets=$(tcpdump -nr $1 2>/dev/null | wc -l)
echo $packets

echo "----------"

echo "TCP sources in % compared to total sources:"
tcp=$((100 * unique_tcp / sources))
echo $tcp

echo "UDP sources in % compared to total sources:"
udp=$((100 * unique_udp / sources))
echo $udp

echo "TCP packets in % compared to total packets:"
t_packets=$(tcpdump -nr $1 tcp 2>/dev/null | wc -l)
tcp_packets=$((100 * t_packets / packets))
echo $tcp_packets

echo "UDP packets in % compared to total packets:"
u_packets=$(tcpdump -nr $1 udp 2>/dev/null | wc -l)
udp_packets=$((100 * u_packets / packets))
echo $udp_packets




#Create destination addresses for loop below
tcpdump -ttttnr $1 2>/dev/null | awk -F" "  '{print $1","$2","$6}' > script1_destinations
cat script1_destinations | awk -F: '{print $1","$3}' | awk -F, '{print $1","$2","$4}' | cut -d"." -f -4 > script1_destinations_cleaned

#Produce a count of the number of unique sources and average packets received per hour for the duration. This is in the format of a csv: date,hour,unique sources,average packets/destination.
tcpdump -ttttnr $1 2>/dev/null | awk -F" " '{print $1}' | sort | uniq > script1_unique_days.txt
tcpdump -ttttnr $1 2>/dev/null | awk -F" " '{print $1","$2","$4}' > e_1
cat e_1 | awk -F: '{print $1","$3}' | awk -F, '{print $1","$2","$4}' | cut -d '.' -f -4 > e_1_cleaned

for i in $(cat script1_unique_days.txt)
do
  cat e_1_cleaned | grep "$i" > $i
  cat $i | sort | uniq | cut -d"," -f -2 > "$i"_date_hour_unique
  cat "$i"_date_hour_unique | uniq -c | awk -F" " '{print $2","$1}' > unique_"$i"
  cat $i | cut -d"," -f -2 | sort | uniq -c | awk -F" " '{print $1}' > packets_"$i"
  paste -d, unique_$i packets_$i > merged_"$i"
  cat merged_"$i" >> script1_all_merged.csv

  #Now count all the destination addresses
  cat script1_destinations_cleaned | grep "$i" > destinations_"$i"
  cat destinations_"$i" | sort | uniq | cut -d"," -f -2 > "$i"_destinations_date_hour_unique
  cat "$i"_destinations_date_hour_unique | uniq -c | awk -F" " '{print $2","$1}' > destinations_unique_"$i"
  cat destinations_unique_"$i" >> merged_destinations.csv
  rm -r $i
  rm -r "$i"_date_hour_unique
  rm -r unique_"$i"
  rm -r packets_"$i"
  rm -r merged_"$i"
  rm -r destinations_"$i"
  rm -r "$i"_destinations_date_hour_unique
  rm -r destinations_unique_"$i"
done
echo ""




echo "---------- Top 10 TCP ports: ----------"
tcpdump -nr $1 tcp 2>/dev/null | awk -F" " '{print $5}' | awk -F. '{print $5}' | sed 's/://g' | sort | uniq -c | sort -nr | head
echo ""




echo "---------- Top 10 UDP ports: ----------"
tcpdump -nr $1 udp 2>/dev/null | awk -F" " '{print $5}' | awk -F. '{print $5}' | sed 's/://g' | sort | uniq -c | sort -nr | head
echo ""

#Clean Up
rm -r script1_destinations
rm -r script1_destinations_cleaned
rm -r script1_unique_days.txt
rm -r e_1
rm -r e_1_cleaned

echo "---------- Instructions: ----------"
echo "In file script1_all_merged.csv you find all source IPs from every hour in the format 'date, hour, source count, total packets.'"
echo "In the file merged_destinations.csv you find the count of all destination IPs from every hour in the same format."
echo "To create a graph import both files to excel and attach the second column of merged_destinations.csv as a new column to the other file."
