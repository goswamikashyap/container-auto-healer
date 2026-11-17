#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"
MONITOR_SCRIPT="$SCRIPT_DIR/monitor.sh"
CRON_JOB="*/2 * * * * $MONITOR_SCRIPT"

chmod +x "$MONITOR_SCRIPT"

if ! pgrep -x "cron" > /dev/null; then
    sudo service cron start
fi

if crontab -l 2>/dev/null | grep -Fq "$MONITOR_SCRIPT"; then
    echo "Cron job is already set up!"
else
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "Success! Scheduled: $CRON_JOB"
fi

