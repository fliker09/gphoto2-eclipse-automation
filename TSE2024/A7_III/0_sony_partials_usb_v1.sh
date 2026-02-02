#!/bin/bash
# Alexandru Barbovschi (c) 2024-2026
# Uncomment the line below to show the execution of the script in full detail.
#set -x
# Uncomment the line below to execute the script step by step (except for functions).
#trap read debug

# This script is meant to shoot a burst of shots for partial phases of the eclipse.

# Define the extension of the files which will be dumped from the camera. For TSE2024
# I've chosen RAW & JPEG trick (dump ARW to the SD card and dump JPG to the computer), due
# to the low speed of transfer even through USB-C interface, despite the computer having
# USB3 capability. As it turned out, while working on SEC2025, I've discovered that
# it was the cable to blame, it supported only USB2 speeds -_-
# Unpleasant discovery, but technically speaking, the script experienced no issues,
# it's just that I could have taken more shots in the same timeframe. Though, for this
# script specifically it doesn't quite apply, as we are shooting here partials and
# nothing else after that, so the number of shot frames wouldn't really change.
EXTENSION=JPG
# Define burst duration in seconds.
PARTIAL_DURATION=4


# Identify camera's USB port. We are looking specifically for Sony A7 III, using 'III' as
# the search term. This is deffo not a robust approach! We should use the full camera's name,
# which can also be used in the gphoto2's calls as well (for '--camera' option). The problem is
# that depending on the name, the 'awk' command needs to be adjusted accordingly. '$6' represents
# column number in the gphoto2 output line, which can change based on the whitespaces in the name.
# For the TSE2026, this function needs to be rewritten to make it fully robust for any camera name!
verify_camera_presence()
    {
        # Uncomment the line below to execute the function step by step
        #trap read debug
        # If you did uncomment the line above - uncomment the last line as well,
        # to limit this mode to this function alone!
        
        sony_port=$(gphoto2 --auto-detect 2>/dev/null | grep III | awk '{print $6}')

        if [ "$sony_port" == "" ]
        then
            echo "Camera is not detected / connected!"
            echo
            return 1
        fi
        
        #trap - debug
    }

# Configure the relevant camera's parameters and ensure that they are properly set!
# Sony cameras are quite prone to "drift" when setting a parameter, which leads to
# the value to be set to a neighboring one instead. This is especially problematic
# with shutter speed value, which is why we try it 10 times instead of just 3 times.
prep_camera()
    {
        # Uncomment the line below to execute the function step by step
        #trap read debug
        # If you did uncomment the line above - uncomment the last line as well,
        # to limit this mode to this function alone!
        
        desired_capture_mode=$1
        desired_iso=$2
        desired_shutter_speed=$3
        desired_image_quality=$4
        
        echo "Configuring camera parameters for $5! (detailed timings follow)"
        time gphoto2 --port $sony_port \
                --set-config-value "/main/capturesettings/imagequality=$desired_image_quality" \
                --set-config-value "/main/capturesettings/capturemode=$desired_capture_mode" \
                --set-config-value "/main/imgsettings/iso=$desired_iso" \
                --set-config-value "/main/capturesettings/shutterspeed=$desired_shutter_speed"
        echo
        
        for i in 1 2 3
        do
            current_image_quality="$(gphoto2 --port $sony_port --get-config '/main/capturesettings/imagequality' | grep Current | cut -d ':' -f 2 | sed 's/^\ //')"
            if [ "$current_image_quality" != "$desired_image_quality" ]
            then
                echo "Setting once more the image quality to $desired_image_quality! (detailed timings follow)"
                time gphoto2 --port $sony_port \
                        --set-config-value "/main/capturesettings/imagequality=$desired_image_quality"
                echo
                sleep 0.1
            else
                break
            fi
        done
        
        for i in 1 2 3
        do
            current_capture_mode="$(gphoto2 --port $sony_port --get-config '/main/capturesettings/capturemode' | grep Current | cut -d ':' -f 2 | sed 's/^\ //')"
            if [ "$current_capture_mode" != "$desired_capture_mode" ]
            then
                echo "Setting once more the capture mode to $desired_capture_mode! (detailed timings follow)"
                time gphoto2 --port $sony_port \
                        --set-config-value "/main/capturesettings/capturemode=$desired_capture_mode"
                echo
                sleep 0.1
            else
                break
            fi
        done

        for i in 1 2 3
        do
            current_iso="$(gphoto2 --port $sony_port --get-config '/main/imgsettings/iso' | grep Current | cut -d ' ' -f 2)"
            if [ "$current_iso" != "$desired_iso" ]
            then
                echo "Setting once more the ISO to $desired_iso! (detailed timings follow)"
                time gphoto2 --port $sony_port \
                        --set-config-value "/main/imgsettings/iso=$desired_iso"
                echo
                sleep 0.1
            else
                break
            fi
        done

        for i in $(seq 1 10)
        do
            current_shutter_speed="$(gphoto2 --port $sony_port --get-config '/main/capturesettings/shutterspeed' | grep Current | cut -d ' ' -f 2)"
            if [ "$current_shutter_speed" != "$desired_shutter_speed" ]
            then
                echo "Setting once more the shutter speed to $desired_shutter_speed! (detailed timings follow)"
                time gphoto2 --port $sony_port \
                        --set-config-value "/main/capturesettings/capturemode=$desired_capture_mode" \
                        --set-config-value "/main/imgsettings/iso=$desired_iso" \
                        --set-config-value "/main/capturesettings/shutterspeed=$desired_shutter_speed"
                echo
                sleep 0.1
            else
                break
            fi
        done
        
        #trap - debug
    }

# Shoot either a burst or a bracketing sequence.
# For this specific script it will be always a burst sequence.
# Bracketing was mentioned only because this function is used in totality script as well.
shoot_frames()
    {
        # Uncomment the line below to execute the function step by step
        #trap read debug
        # If you did uncomment the line above - uncomment the last line as well,
        # to limit this mode to this function alone!
        
        echo "Shooting frames for $2! (detailed timings follow)"
        echo
        bulb_duration=$1
        time gphoto2 --port $sony_port \
                --bulb $bulb_duration \
                --capture-image-and-download \
                --filename %Y_%m_%d_%H_%M_%S_%n.$EXTENSION
        echo
        
        #trap - debug
    }

# Get the finishing time and report the total duration of the script.
exit_sequence()
    {
        # Uncomment the line below to execute the function step by step
        #trap read debug
        # If you did uncomment the line above - uncomment the last line as well,
        # to limit this mode to this function alone!

        end_time=$(date +%s)

        echo
        echo "Total duration: $(( $end_time - $start_time )) seconds"
        echo

        #trap - debug
    }


#---------- main() ----------

# Save the starting time of the script, which is later used by exit_sequence() function.
start_time=$(date +%s)

# Check for camera's presence. If it's not connected - give 3 chances to plug it in.
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
        echo "Sony camera port: $sony_port"
        echo
        break
    else
        echo "You have 10 seconds to re-connect / restart Sony camera! (attempt $i out of 2)"
        echo
        sleep 10
    fi
done

# Let's check on our battery levels - are they OK? Is our external power keeping it well?
bat_level=$(gphoto2 --port $sony_port --get-config '/main/status/batterylevel' | sed -n 4p | cut -d ' ' -f 2)
echo "Current battery level is $bat_level"
echo

sleep 1

# Set all the relevant parameters for the camera to the desired values.
# As for the last parameter, 'partial', it's used for the output log text.
prep_camera "Continuous Low Speed" "100" "1/1600" "RAW+JPEG (Std)" "partial"

date +"%Y-%m-%dT%H:%M:%S.%3N%:z"
echo

# Fire a burst sequence for the defined duration.
shoot_frames $PARTIAL_DURATION "partial"

date +"%Y-%m-%dT%H:%M:%S.%3N%:z"
echo

# Report the total duration of the entire script.
exit_sequence
