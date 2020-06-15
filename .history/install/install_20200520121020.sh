#!/usr/bin/env bash

cho "Parameter arg: $1"

copy_to_ezydir()
{
  mkdir -p /usr/local/ezyadmin
  cd /usr/local/ezyadmin
  cp -af ../agent /usr/local/ezyadmin/
}
setup_linux()
{
  echo "Setup Patch Manager for linux ..."
}