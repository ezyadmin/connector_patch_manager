#!/bin/bash
#
maxdelay=$((3*60))  # 14 hours from 9am to 11pm, converted to minutes
for ((i=1; i<=20; i++)); do
    delay=$(($RANDOM%maxdelay)) # pick an independent random delay for each of the 20 runs
    (sleep $((delay*60)); /path/to/phpscript.php) & # background a subshell to wait, then run the php script
done