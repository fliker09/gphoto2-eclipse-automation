#!/bin/bash
# Alexandru Barbovschi (c) 2024-2026
# Uncomment the line below to show the execution of the script in full detail.
#set -x
# Uncomment the line below to execute the script step by step.
#trap read debug

# This script is meant to help solve the bottleneck created by the slow write
# speed of the SD card from which runs the system on Raspberry Pi computer. The idea
# is to copy the the totality script into RAM storage and execute it there. This means
# that the files will be also dumped there, so you need to be careful not to overrun
# its capacity (run 'df -h' and theck for '/dev/shm' - how big is the available space there?).
# Alternative is to run the script on external storage, either USB3 SSD or NVME, if supported.

# Define what is the file extension of the files dumped onto computer by the totality script.
EXTENSION=JPG
# Define the path to your totality script.
SCRIPT_PATH="/home/astroberry/TSE2024/A7_III/1_sony_totality_usb_v1.sh"
# If we leave this variable empty - dumped files will be removed, which is OK if are saving
# ARW files on the camera. If we are dumping ARW to the computer  - we don't want them
# removed, but moved to a storage instead. Define the absolute path to it with this variable.
SYNC_FOLDER=""


echo
date +"%Y-%m-%dT%H:%M:%S.%3N%:z"
echo
echo "Copying the totality script and executing it..."
echo
# Change directory into RAM storage, copy the script, execute.
# Afterwards, remove the script.
cd /dev/shm
cp "$SCRIPT_PATH" .
./1_sony_totality_usb_v1.sh $1
rm 1_sony_totality_usb_v1.sh
# Check if we need to move the dumped files or not. If we do - check if the destination exists.
# If it does - move the files and flush the file buffers by calling 'sync' command.
# If we don't have to move the files - just remove them!
if [ "$SYNC_FOLDER" != "" ]
then
    if [ -e "$SYNC_FOLDER" ]
    then
        echo "Moving the files to $SYNC_FOLDER..."
        echo
        mv *.$EXTENSION "$SYNC_FOLDER"
        sync
        echo "Done!"
        echo
    else
        echo "Destination folder does not exist, leaving the files as is."
        echo "Please move them out of RAM storage yourself ASAP!"
        echo
    fi
else
    echo "Removing the files!"
    echo
    rm *.$EXTENSION
fi
echo
date +"%Y-%m-%dT%H:%M:%S.%3N%:z"
echo
echo "Script execution in RAM and clean up are complete!"
echo
