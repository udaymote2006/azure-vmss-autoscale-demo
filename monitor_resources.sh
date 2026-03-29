#!/bin/bash
THRESHOLD=75
INTERVAL=30
CONSECUTIVE_CHECKS=5
COUNT=0
LOG=/var/log/resource-monitor.log

while true; do
  # CPU usage (idle % from mpstat, invert to get used %)
  CPU=$(mpstat 1 1 | tail -1 | awk '{print 100 - $NF}' | bc)
  RAM_USED=$(free -m | awk 'NR==2 {print $3/$2*100}' | bc)

  echo "$(date) - CPU: ${CPU}% | RAM: ${RAM_USED}% " >> $LOG

  if (( $(echo "$CPU > $THRESHOLD" | bc -l) )); then
    COUNT=$((COUNT+1))
    if [ $COUNT -ge $CONSECUTIVE_CHECKS ]; then
      echo "$(date) - HIGH USAGE DETECTED! Triggering Azure scale-out..." >> $LOG
      /home/admin/deploy_to_azure.sh >> $LOG 2>&1
      COUNT=0
      sleep 300  # cooldown
    fi
  else
    COUNT=0
  fi
  sleep $INTERVAL
done