#!/usr/bin/env bash

# Echos time left to charge/discharge battery

#status=$(cat /sys/class/power_supply/BAT0/status)
bat=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0)
bat_time=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep "time to")
bat_lf=$(echo $bat_time | cut -d' ' -f4)
hm=$(echo $bat_time | cut -d' ' -f5)

# If full
if [[ $bat == *"100%"* ]] && [ "${bat_time}" == "" ]; then
    echo " Full"
    exit 0
fi

# If no match
if [ "${bat_time}" == "" ]; then
    echo " --- "
    exit 0
fi

# If minutes
if [ "${hm}" == "hours" ]; then
    hm="h"
else
    hm="m"
fi

if [ ${#bat_lf} == 4 ]; then
    echo $bat_lf$hm
else
    echo " "$bat_lf$hm
fi
