#!/bin/bash
#set -x
#trap read debug

EXTENSION=JPG


echo
date +"%Y-%m-%dT%H:%M:%S.%3N%:z"
echo
echo "Copying the totality script and executing it..."
echo
cd /dev/shm
cp /home/astroberry/TSE2024/A7_III/RPi4/1_sony_totality_usb_v1.sh .
./1_sony_totality_usb_v1.sh $1
rm *.$EXTENSION 1_sony_totality_usb_v1.sh
echo
date +"%Y-%m-%dT%H:%M:%S.%3N%:z"
echo
echo "Execution in RAM and clean up is complete!"
echo
