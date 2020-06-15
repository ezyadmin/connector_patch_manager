#!/usr/bin/env bash

echo "Parameter arg: $1"

# ========= variable ============
DATE_NOW=$(date '+%d/%m/%Y %H:%M:%S')

MAIN()
{
  mkdir -p /usr/local/ezyadmin/connector_patch_manager#
  cd /usr/local/ezyadmin/connector_patch_manager#
  cp -af ./../agent /usr/local/ezyadmin/

  EZBIN=/usr/local/bin/ezinstall_patch_mgr
  if [ ! -h $EZBIN ]; then
    echo "=> File doesn't exist"
    # cp -f ../script/ezinstall_patch_mgr /usr/local/bin/ezinstall_patch_mgr
  fi
  
  echo "$DATE_NOW" > /usr/local/ezyadmin/agent/install
}
MAIN
