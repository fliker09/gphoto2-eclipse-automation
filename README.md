# **Eclipse automation using gphoto2**

Currently, you can find here the scripts used for the fully automatic shooting of the Total Solar Eclipse on April 8th 2024. They did their job flawlessly - partial phases, Baily's Beads and totality were captured without any issues!

Here is the timeline of attempts at automation with `gphoto2`:

*   _**2019 July 2nd**_. Total Solar Eclipse. 2 cameras, Nikon D610 to capture wide-angle shots and Sony A7S to shoot through telescope. Nikon had no issues, beside my poor framing. Sony was fine till C3. I was using two separate scripts for Diamond Rings + Baily's Beads and totality. Totality script finished later then expected and clashed with the DR + BB script. It wasn't fatal, still got the frames! Just the timing was off, breaking symmetry. It took me 6 years to understand what exactly went wrong with the totality script... More details about it in my [article](https://fliker09.wordpress.com/2026/02/11/remote-control-of-sony-cameras-for-solar-eclipses/).
*   _**2019 November 11th**_. Transit of Mercury. Nikon D610 shooting through telescope. Nothing too fancy, rapid shooting at ingress/egress and just regular shots every 5 minutes in between. Ingress caught perfectly, egress clouded out.
*   _**2021 November 18th**_. Partial Lunar Eclipse. Nikon D610 shooting wide-angle shots. Due to the limitation of the internal bracketing (only 3 shots with 3EV step), used `gphoto2` to expand the range and make it shoot the entirety of the eclipse in HDR mode. No issues encountered!
*   _**2023 April 20th**_. Total Solar Eclipse. 3 cameras in total! Sony A7 II to capture wide-angle shots. Sony A7 III capturing close-up 4K HDR video. Sony A7S to capture shots at 85mm. Partial phases were captured without a hitch. Totality on the other hand... Human factor screwed it up. Functionally-wise scripts should have worked flawlessly, but they started at the wrong time because of the wrong timestamps in the timing files, due to the late night testings 😕 Harsh lesson! Was able to salvage the totality from the video though 🚀️
*   _**2024 April 8th**_. Total Solar Eclipse. The harsh lesson from 2023 was applied here! Totality script gained simulation/testing modes, to avoid touching production timings. It paid off, the scripts worked flawlessly! Sony A7S II recorded a 4K video and Sony A7 III captured all the phases without a hitch, including a high-speed shooting of Baily's Beads.

Since the last attempt was so successful, I've decided to publish the scripts for it. I've went through them and added comments in the code to explain the inner workings. Hopefully they clarify most of the things! In-depth analysis and explanation of the solutions developed for these scripts are provided in my [article](https://fliker09.wordpress.com/2026/02/11/remote-control-of-sony-cameras-for-solar-eclipses/), which should cover both the current repo and this one:

[https://github.com/fliker09/sec2025-scripts](https://github.com/fliker09/sec2025-scripts)

A detailed description of the structure of TSE2024 folder follows:

*   `A7S_II` - contains the scripts for shooting video using Sony A7S II, both for partial phases (`0_sony_partials_v1.sh`) and totality (`1_totality_v1.sh`).
*   `A7_III` - contains script for shooting photos using Sony A7 III, both for partial phases (`0_sony_partials_usb_v1.sh`) and Baily's Beads + totality (`1_sony_totality_usb_v1.sh`). There is also a helper script (`2_copy_to_shm_v1.sh`) for computers with slow system storage (e.g. Raspberry Pi running from SD card).
*   `C2.txt` - contains the exact timing for C2. The format must be compatible with the `date` utility!
*   `C3.txt` - contains the exact timing for C3. The format must be compatible with the `date` utility!
*   `crontab_sample.txt` - provides a template for configuring the `cron`, which is the scheduler of choice.
*   `Duration.txt` - define the duration in seconds for the video recording dony by Sony A7S II. Must be integer!
*   `SIM_C2.txt` - contains the simulation timing for C2. The format must be compatible with the `date` utility!
*   `SIM_C3.txt` - contains the simulation timing for C3. The format must be compatible with the `date` utility!

To run the scripts please ensure that your system has `bash`, `sed` and `awk` (I am not listing the full list of utilities because the rest of them are pretty much standard for any Unix-alike OS).

Warning for Mac OS X users - these utilities might work in a slightly different way than on Linux (e.g. `date` might not return nanoseconds), which in turn might cause the scripts to misbehave.

The most important tool is, of course, `gphoto2`. You can install it from your package manager and be done with it. But if might be not the latest available version. In this case you might need to compile it yourself. If you run a Debian-based system like Ubuntu - clone this repo and run the script:

[https://github.com/fliker09/gphoto2-updater](https://github.com/fliker09/gphoto2-updater)

No need to uninstall your current version - this script will install it in parallel and take precedence over the system's version. Personally used it a number of Debian and Ubuntu systems, older and newer, and it worked without any additional efforts.

If you have any suggestions for improvements and/or clarifications - please open an `Issue` here on GitHub! If you would like to get in touch and discuss collabaration (e.g. testing a new camera) - please contact me directly at `alex_dot_sec2025_at_capturetheuniverse_dot_com`!

If you want to learn more about gphoto2 and eclipse photography automation for Sony cameras - this comprehensive article goes in-depth about it all:

[https://fliker09.wordpress.com/2026/02/11/remote-control-of-sony-cameras-for-solar-eclipses/](https://fliker09.wordpress.com/2026/02/11/remote-control-of-sony-cameras-for-solar-eclipses/)