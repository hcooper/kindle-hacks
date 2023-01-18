#!/bin/bash
set -euo pipefail

KINDLE_ID=$(hostname | grep -o ".$"):

# This script is highly inspired by onlinescreensaver (https://www.mobileread.com/forums/showthread.php?t=236104).
# However on my device (a PW3) I had problems with power management (sometimes it wouldn't
# sleep, othertimes it would't wake up, etc...). So instead the script kills the regular
# power management system (powerd), and uses `rtcwake` to schedule wake-ups directly. The only
# real downside of this is you loose physical control of the device while it's asleep
# (except for long-press reboots). However that's not a problem as the point is this is
# now a display-only device (managed via SSH).

# Flush iptables. The device runs on a locked-down local-only vlan so I want to be
# able to ping the device etc.
iptables -P INPUT ACCEPT
iptables -F

# Stop power management - we're going to do our own.
stop powerd >/dev/null 2>&1 || true
pkill powerd >/dev/null 2>&1 || true

# Set config here rather than
IMAGE_URI="http://kindle_screensaver.ak:8080/$KINDLE_ID" # Runs hass-lovelace-kindle-screensaver
SCREENSAVERFOLDER=/tmp
SCREENSAVERFILE=$SCREENSAVERFOLDER/bg_ss00.png
NETWORK_TEST_CMD="curl --silent --fail http://kindle_screensaver.ak/ >/dev/null"
NETWORK_TIMEOUT=30
TMPFILE=/tmp/tmp.onlinescreensaver.png

run() {
while true; do

    BATTERY_LEVEL=$(cat /sys/devices/system/wario_battery/wario_battery0/battery_capacity)
    IS_CHARGING=$(cat /sys/devices/system/wario_charger/wario_charger0/charging)

    TIMER=${NETWORK_TIMEOUT} # number of seconds to attempt a connection
    CONNECTED=0              # whether we are currently connected

    while [ 0 -eq $CONNECTED ]; do
        # test whether we can ping outside
        sh -c "$NETWORK_TEST_CMD" && CONNECTED=1

        # if we can't, checkout timeout or sleep for 1s
        if [ 0 -eq $CONNECTED ]; then
            TIMER=$(($TIMER - 1))
            if [ 0 -eq $TIMER ]; then
                logger -s "No internet connection after ${NETWORK_TIMEOUT} seconds, aborting."
                break
            else
                sleep 1
            fi
        fi
    done

    if [ 1 -eq $CONNECTED ]; then

        # Extra parameters to log battery informaton to hass-lovelace-kindle-screensaver
        if wget -q "$IMAGE_URI?batteryLevel=$BATTERY_LEVEL&isCharging=$IS_CHARGING" -O $TMPFILE; then
            # To avoid ownership errors cp+rm rather than mv
            cp $TMPFILE $SCREENSAVERFILE
            rm -f $TMPFILE
            logger -s "Screen saver image updated. Refreshing screen."

            # refresh screen
            eips -f -g $SCREENSAVERFILE
        else
            logger -s "Error updating screensaver"
        fi
    fi

    # Fetch the config file which controls how long we sleep for
    SLEEP_DURATION=$(curl --silent --fail http://10.10.3.1/kindle-sleep-duration || echo 0)

    if [ $SLEEP_DURATION -gt 0 ]; then
        logger -s "Going back to sleep for $SLEEP_DURATION. Zzzzzz..."
        /usr/sbin/rtcwake -s $SLEEP_DURATION
    else
        logger -s "Failed to get sleep duration, pausing for 60s."
        sleep 60
    fi

done
}

run &
