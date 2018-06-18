#!/bin/bash
#Chromecast, Jacob iPhone, ITMDKLT027, Pedes iPhone
staticdevicesmac=("54:60:09:fc:47:a2" "f0:98:9d:d5:bc:aa" "00:24:d7:ba:10:68" "dc:56:e7:a2:28:c5")

if [[ $2 == "AP-STA-DISCONNECTED" ]]
then
  if [[ ! " ${staticDevicesMac[@]} " =~ " ${3} " ]]
  then
    dhcp_release $1 10.0.0.20 $3
  fi

  #if [[ " ${staticDevicesMac[@]} " =~ " ${3} " ]]
  #then
    #echo "2: someone has disconnected with mac id $3 on $1"
  #fi
fi