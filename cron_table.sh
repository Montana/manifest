#!/bin/bash

# Author Montana Mendy

# Run /bin/false at 1:35 on the mon,tue,wed and the 4th of every month
35    1     4     *     mon-wed  /bin/false
  
# Run /bin/true at 22:25 on the 2nd Tuesday of every month
25    22    2     3     *        /bin/true
  
# Run /bin/false at 2:00 every Monday, Wednesday and Friday
0     2     *     *     1-5/2    /bin/false

# Randomized check via Cron to have Travis check for failures (esp on Docker images, or bad manifests) 

maxdelay=$((14*60))  # 14 hours from 9am to 11pm, converted to minutes
for ((i=1; i<=20; i++)); do
    delay=$(($RANDOM%maxdelay)) 
    (sleep $((delay*60)); /path/to/script) & 
done
