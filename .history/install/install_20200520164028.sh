#!/usr/bin/env bash

echo "Parameter arg: $1"

# ========= variable ============
DATE_NOW=$(date '+%d/%m/%Y %H:%M:%S')

main()
{
  mkdir -p /usr/local/ezyadmin
  cd /usr/local/ezyadmin
  cp -af ../agent /usr/local/ezyadmin/
  cp -f cp.txt cp2.txt
  echo "$DATE_NOW" > /usr/local/ezyadmin/agent/install
}

