#!/bin/bash
# Alexandru Barbovschi (c) 2024-2026
# Uncomment the line below to show the execution of the script in full detail.
#set -x
# Uncomment the line below to execute the script step by step (except for functions).
#trap read debug

# This scripts handles both Baily's Beads and totality shooting. Handling each in its own
# separate script is a possibility, but it might be risky, in case they clash timing-wise.
# That's what happened in 2019 and since then I've decided to handle them together.

# For Baily's Beads we shoot a burst sequence. We define here duration in seconds.
# WARNING: set this value so that the number of shot frames won't overrun camera's buffer.
BB_DR_DURATION=5
# Define the extension of the files which will be dumped from the camera. For TSE2024
# I've chosen RAW & JPEG trick (dump ARW to the SD card and dump JPG to the computer), due
# to the low speed of transfer even through USB-C interface, despite the computer having
# USB3 capability. As it turned out, while working on SEC2025, I've discovered that
# it was the cable to blame, it supported only USB2 speeds -_-
# Unpleasant discovery, but technically speaking, the script experienced no issues,
# it's just that I could have taken more shots in the same timeframe for totality.
EXTENSION=JPG
# How many cycles we want to shoot for totality? Each cycle consists of
# three bracketing sequences, which together create 15 shots with 1EV step.
# This number is found experimentally. Ensure you have some room after C2 and
# before C3, so Baily's Beads shooting won't clash with totality shooting!
TOTALITY_CYCLES=3
# Define if we want to run production, simulation or testing mode:
# 1. '1_sony_totality_usb_v1.sh' - this runs the script in production mode;
# 2. '1_sony_totality_usb_v1.sh simulation' - this runs the script in simulation mode;
# 3. '1_sony_totality_usb_v1.sh testing' - this runs the script in testing mode;
TEST_RUN=$1
# Define the duration of your test totality.
TEST_DURATION=108
# This basically defines when is C2 from the moment of starting this script. Please don't
# set it too short, to allow the script to configure the camera and shoot Baily's Beads.
TEST_PRESTART=54.5
# Define the folder where eclipse info is stored.
TIMINGS_PATH=/home/astroberry/TSE2024


# Identify camera's USB port. We are looking specifically for Sony A7 III, using 'III' as
# the search term. This is deffo not a robust approach! We should use the full camera's name,
# which can also be used in the gphoto2's calls as well (for '--camera' option). The problem is
# that, depending on the name, the 'awk' command needs to be adjusted accordingly. '$6' represents
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

# Shoot either a burst or a bracketing sequence, depending on the phase of the eclipse.
# Regarding the '--bulb' option. On Sony cameras it allows to emulate the pressing of
# the shutter release button! It is weird, but also very convenient for our purposes.
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

# This segment of code is meant to make testing easy and safe. Instead of touching production
# values of the eclipse timings, we can just simulate values and use them instead. I wish I did
# this back in 2023 and avoided the disaster -_- Oh well, you fail, you learn!
# Production and Simulation are basically identical, the difference is only from which files they
# read the values for the timings. Testing mode calculates the timings based on the current time
# and the defined variables in the header of the script.
if [ "$TEST_RUN" == "" ]
then
    echo "Entering production mode!"
    echo
    c2_timestamp=$(date --date="$(cat "$TIMINGS_PATH"/C2.txt)" +'%s.%3N')
    c3_timestamp=$(date --date="$(cat "$TIMINGS_PATH"/C3.txt)" +'%s.%3N')
    if [ "$c2_timestamp" == "" ]
    then
        echo "C2 timings are absent, aborting the script!"
        echo
        exit 1
    fi
    if [ "$c3_timestamp" == "" ]
    then
        echo "C3 timings are absent, aborting the script!"
        echo
        exit 1
    fi
elif [ "$TEST_RUN" == "simulation" ]
then
    echo "Entering simulation mode!"
    echo
    c2_timestamp=$(date --date="$(cat "$TIMINGS_PATH"/SIM_C2.txt)" +'%s.%3N')
    c3_timestamp=$(date --date="$(cat "$TIMINGS_PATH"/SIM_C3.txt)" +'%s.%3N')
    if [ "$c2_timestamp" == "" ]
    then
        echo "C2 timings are absent, aborting the script!"
        echo
        exit 1
    fi
    if [ "$c3_timestamp" == "" ]
    then
        echo "C3 timings are absent, aborting the script!"
        echo
        exit 1
    fi
else
    echo "Entering testing mode!"
    echo
    c2_timestamp=$(echo "scale=3;$(date +%s.%3N) + $TEST_PRESTART" | bc)
    c3_timestamp=$(echo "scale=3;$(date +%s.%3N) + $TEST_PRESTART + $TEST_DURATION" | bc)
    echo
    echo "C2 test date: $(date --date=@"$c2_timestamp")"
    echo
    echo "C3 test date: $(date --date=@"$c3_timestamp")"
    echo
fi

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
# As for the last parameter, 'BB', it's used for the output log text.
prep_camera "Continuous Low Speed" "100" "1/8000" "RAW+JPEG (Std)" "BB"

# Calculate how much time is left till we have to start shooting Baily's Beads.
c2_diff=$(echo "scale=3;$c2_timestamp - $(date +%s.%3N) - $BB_DR_DURATION + 1" | bc)

echo "Sleeping for $c2_diff seconds..."
echo
sleep $c2_diff

# This will be used for reporting the duration on shooting Baily's Beads around C2.
start_time_1=$(date +%s)

date +"%Y-%m-%dT%H:%M:%S.%3N%:z"
echo

# Shoot the Baily's Beads around C2.
shoot_frames $BB_DR_DURATION "BB"

end_time_1=$(date +%s)

# This will be used for reporting the duration on shooting totality.
start_time_2=$(date +%s)

date  +"%Y-%m-%dT%H:%M:%S.%3N%:z"
echo

# As requested, we are gonna shoot the 15 frames set 3 times. It could have been more,
# if not for my mistake with the USB cable, as described in the header of the script.
for i in $(seq 1 $TOTALITY_CYCLES)
do
    prep_camera "Bracketing C 3.0 Steps 5 Pictures" "100" "1/80" "RAW+JPEG (Std)" "totality"
    date +"%Y-%m-%dT%H:%M:%S.%3N%:z"
    echo
    shoot_frames 2 "totality"
    prep_camera "Bracketing C 3.0 Steps 5 Pictures" "100" "1/40" "RAW+JPEG (Std)" "totality"
    date +"%Y-%m-%dT%H:%M:%S.%3N%:z"
    echo
    shoot_frames 3 "totality"
    prep_camera "Bracketing C 3.0 Steps 5 Pictures" "100" "1/20" "RAW+JPEG (Std)" "totality"
    date +"%Y-%m-%dT%H:%M:%S.%3N%:z"
    echo
    shoot_frames 5 "totality"
done

date +"%Y-%m-%dT%H:%M:%S.%3N%:z"
echo

end_time_2=$(date +%s)

prep_camera "Continuous Low Speed" "100" "1/8000" "RAW+JPEG (Std)" "BB"

# Calculate how much time is left till we have to start shooting Baily's Beads around C3.
c3_diff=$(echo "scale=3;$c3_timestamp - $(date +%s.%3N) - 1" | bc)

echo "Sleeping for $c3_diff seconds..."
echo
sleep $c3_diff

# This will be used for reporting the duration on shooting Baily'd Beads around C3.
start_time_3=$(date +%s)

date +"%Y-%m-%dT%H:%M:%S.%3N%:z"
echo

# Shoot the Baily's Beads around C3.
shoot_frames $BB_DR_DURATION "BB"

end_time_3=$(date +%s)

echo
echo "BBs & DRs around C2 duration: $(( $end_time_1 - $start_time_1 ))"
echo
echo "BBs & DRs around C3 duration: $(( $end_time_3 - $start_time_3 ))"
echo
echo "Totality duration: $(( $end_time_2 - $start_time_2 ))"
echo

# Report the total duration of the entire script.
exit_sequence
