#!/usr/bin/env bash

echo "Parameter arg: $1"

# ========= variable ============
DATE_NOW=$(date '+%d/%m/%Y %H:%M:%S')

MAIN()
{
  mkdir -p /usr/local/ezyadmin/connector_patch_manager
  cd /usr/local/ezyadmin/connector_patch_manager
  cp -af ./agent /usr/local/ezyadmin/
  chmod 755 -R agent
  chmod 755 -R script

  EZBIN=/usr/local/bin/ezinstall_patch_mgr
  if [ ! -h $EZBIN ]; then
    echo "=> File doesn't exist"
    ln -s /usr/local/ezyadmin/connector_patch_manager/script/ezinstall_patch_mgr /usr/local/bin/ezinstall_patch_mgr

  fi
  
  echo "$DATE_NOW" > /usr/local/ezyadmin/connector_patch_manager/install.log
}
MAIN
