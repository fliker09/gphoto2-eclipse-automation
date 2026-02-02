#!/bin/bash
# Alexandru Barbovschi (c) 2025-2026
# Uncomment the line below to show the execution of the script in full detail.
#set -x
# Uncomment the line below to execute the script step by step (except for functions).
#trap read debug

# Record a video of the Diamond Rings, Baily's Beads and totality!

# Define the folder where eclipse info is stored.
TIMINGS_PATH=/home/astroberry/TSE2024

# Identify camera's USB port. We are looking specifically for Sony A7S II, using 'A7S' as
# the search term. This is deffo not a robust approach! We should use the full camera's name,
# which can also used in the gphoto2's calls as well (for '--camera' option). The problem is
# that depending on the name, the 'awk' command needs to adjusted accordingly. '$5' represents
# column name in the gphoto2 output line. Depending on the csmera's name, this value can change.
# For the TSE2026 this function needs to be rewritten to make it fully robust for any camera name!
verify_camera_presence()
    {
        #trap read debug
        
        sony_port=$(gphoto2 --auto-detect 2>/dev/null | grep A7S | awk '{print $5}')

        if [ "$sony_port" == "" ]
        then
            echo "Camera is not detected / connected!"
            echo
            return 1
        fi
        
        #trap - debug
    }

# Get the finishing time and report the total duration of the script.
exit_sequence()
    {
        #trap read debug

        end_time=$(date +%s)

        echo
        echo "Total duration: $(( $end_time - $start_time )) seconds"

        #trap - debug
    }

# A simple function to either start or stop the video recording. Thankfully, it's super
# easy with gphoto2! No need for any external trigger device like I did for TSE2023 -_-
movie_action()
    {
        #trap read debug
        
        if [ "$1" == "Starting" ]
        then
            echo
            echo "$1 movie recording"
            time gphoto2 --port $sony_port --set-config='/main/actions/movie=1'
            echo
        fi
        
        if [ "$1" == "Stopping" ]
        then
            echo
            echo "$1 movie recording"
            time gphoto2 --port $sony_port --set-config='/main/actions/movie=0'
            echo
        fi
        
        #trap - debug
    }

# We check here is the camera is recording or not. Based on the input parameter, we can do
# three things:
# 1. We received 'stop' parameter. If the camera is recording - stop the recording.
# 2. We received 'check' paramater. If the cameras is recording - we report success.
# 3. We received 'check' paramater. If the cameras is not recording - we report failure.
# Note: we will not attempt any retries here.
is_camera_recording()
    {
        #trap read debug

        is_recording=$(gphoto2 --port $sony_port --get-config '/main/other/d21d' 2>/dev/null | sed -n 4p | cut -d ' ' -f 2)
        if [[ $is_recording == 1 && $1 == "stop" ]]
        then
            echo "It seems camera is currently recording, gonna stop it now!"
            echo
            movie_action Stopping
            sleep 1
        fi

        if [[ $is_recording == 1 && $1 == "check" ]]
        then
            echo "Camera seems to be recording just fine"
            echo
        fi

        if [[ $is_recording == 0 && $1 == "check" ]]
        then
            echo "Camera seems not to be recording"
            echo
        fi

        #trap - debug
    }


#---------- main() ----------

# Save the starting time of the script, which is later used by exit_sequence() function.
start_time=$(date +%s)

# Here we either define the duration of the recording ourselves, by adding it to the script's
# invocation (e.g. 1_totality_v1.sh 70) or we read it from the pre-defined file. This approach
# is convenient for testing the script for a shorter duration without the need to touch the
# file which stores the production value for the actual eclipse.
# WARNING: Must use only integer values for the duration.
if [ "$1" != "" ]
then
    DURATION=$1
else
    DURATION=$(cat "$TIMINGS_PATH"/Duration.txt)
fi

# Check for camera's presence. If it's not connected - give 3 chances to connect it.
for i in 1 2 3
do
    verify_camera_presence
    cam_stat=$?
    if [[ $i == 3 && $cam_stat != 0 ]]
    then
        echo "FAILED TO CONNECT CAMERA! ABORTING!"
        echo
        exit_sequence
        exit 1
    fi
    if [ $cam_stat == 0 ]
    then
        echo
        echo "Sony camera port: $sony_port"
        echo
        break
    else
        echo "You have 10 seconds to re-connect / restart Sony camera! (attempt $i out of 2)"
        echo
        sleep 10
    fi
done

# Before we start - let's ensure that camera is not recording!
is_camera_recording stop

# Let's check on our battery levels - are they OK? Is our external power keeping it well?
bat_level=$(gphoto2 --port $sony_port --get-config '/main/status/batterylevel' | sed -n 4p | cut -d ' ' -f 2)
echo "Current battery level is $bat_level"
echo

echo "Configuring initial camera parameters! (detailed timings follow)"
time gphoto2 --port $sony_port \
        --set-config-value '/main/imgsettings/whitebalance=Daylight' \
        --set-config-value '/main/imgsettings/iso=100'
echo

echo
date +"%Y-%m-%dT%H:%M:%S.%3N%:z"
echo

# Signal to start the video recording.
movie_action Starting

sleep 1

# Call upon the function to check if the recording has started or not.
is_camera_recording check

echo
echo "Recording for $DURATION seconds..."
echo
# We need to sleep for one second less, as we already slept for 1 second beforehand.
sleep $(( $DURATION - 1 ))

# Signal the end of the recording!
movie_action Stopping

echo
date +"%Y-%m-%dT%H:%M:%S.%3N%:z"
echo

# Give the camera a bit of time to settle down.
sleep 2

# Verify if the camera is still recording is not.
is_camera_recording check

# Report the total duration of the entire script.
exit_sequence
