#!/bin/bash

function restrict(){
    PORT=$3
    PROTOCOL=$2
    ADDORDELETE=$1

    if [ -z "$3" ]; then
         echo "Need 3 parameters. [insert or delete] [protocol] [port]. Ex: 'xx.sh I tcp 80'";
         exit 0;
    fi
	
	#Restrict connections to 10 per minute for each IP
    iptables -$ADDORDELETE INPUT -p $PROTOCOL --dport $PORT -i eth0 -m state --state NEW -m recent --set
    iptables -$ADDORDELETE INPUT -p $PROTOCOL --dport $PORT -i eth0 -m state --state NEW -m recent --update --seconds 60 --hitcount 10 -j DROP

}

###############################
#######    CONFIG		#######
###############################

AD=I		# I = Insert iptable rules; D = Delete iptables rules.

iptables -$AD INPUT -p tcp ! --syn -m state --state NEW -j DROP                 #Force SYN check
iptables -$AD INPUT -f -j DROP                                                  #Force fragments check
iptables -$AD INPUT -p tcp --tcp-flags ALL ALL -j DROP                          #Drop malformed XMAS packets
iptables -$AD INPUT -p tcp --tcp-flags ALL NONE -j DROP                         #Drop null packages
iptables -$AD INPUT -p ICMP --icmp-type 8 -j DROP                               #Drop ICMP

restrict $AD udp 1200                                                           #Steam
restrict $AD tcp 22                                                             #SSH
restrict $AD tcp 27014:27050                                                    #Steam
restrict $AD udp 27000:27030                                                    #Steam
restrict $AD udp 4380                                                           #Steam
restrict $AD udp 9987                                                           #Teamspeak
restrict $AD tcp 10011                                                          #Teamspeak
restrict $AD tcp 30033                                                          #Teamspeak
restrict $AD tcp 80                                                             #HTTP
restrict $AD tcp 873                                                            #Rsync
restrict $AD tcp 10000                                                          #Webmin
restrict $AD udp 26901:26999                                                    #
restrict $AD tcp 25565                                                          #Minecraft
restrict $AD udp 25565                                                          #Minecraft
echo "Finished adding/removing rules"

iptables-save >/etc/iptables.up.rules
echo "Rules saved to iptables-save"

