#!/bin/sh
# A job that takes 75 seconds - longer than its 60-second schedule.
# Without a lock, copies of it would pile up. With flock -n, they skip.
log=/home/you/cron-lab/out/flock.log
echo "started  $(date -Is)" >> "$log"
sleep 75
echo "finished $(date -Is)" >> "$log"
