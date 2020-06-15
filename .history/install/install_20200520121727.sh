#!/usr/bin/env bash

echo "Parameter arg: $1"

# ========= variable ============
DATE_NOW=$(date '+%d/%m/%Y %H:%M:%S')

copy_to_ezydir()
{
  mkdir -p /usr/local/ezyadmin
  cd /usr/local/ezyadmin
  cp -af ../agent /usr/local/ezyadmin/
}
setup_linux()
{
  echo "Setup Patch Manager for linux ..."
  echo "$DATE_NOW" > /usr/local/ezyadmin/agent/linux
}