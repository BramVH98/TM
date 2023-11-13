#!/bin/bash

#to use this script properly, add it as a cronjob(every 5 minutes)

current_ip="" #this is the ip that should be replaced

check_ip_addr="" #this is the ip that will be checked and taken up if it doesn't respond

default_gw="" #the default gateway for this ip

interface="" #the interface where the ip should sit

if [ -n "$check_ip_addr" ]; then
    # Use the provided IP address in the ping command
    ping -c 5 "$check_ip_addr" > /dev/null #pings 5 times and discards the output
    if [ $? -eq 0 ]; then #checks exit status of last command
    #if pings successful
      result=0
    else
    #if pings failed
    result=1
    fi

    if [ $result -eq 1 ]; then #if the pings failed then this server should take up the ip address for itself
    ip addr add "$check_ip_addr" dev "$interface"
    ip addr del "$current_ip" dev "$interface"
    sleep 2 #adjust if necessary
    ping -c 8 "$default_gw" > /dev/null
    else
      exit 0
    fi
    exit 0
else
   echo "Invalid or empty IP address. Exiting."
fi
exit 0
