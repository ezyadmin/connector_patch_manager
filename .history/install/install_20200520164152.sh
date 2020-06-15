#!/usr/bin/env bash

echo "Parameter arg: $1"

# ========= variable ============
DATE_NOW=$(date '+%d/%m/%Y %H:%M:%S')

main()
{
  mkdir -p /usr/local/ezyadmin
  cd /usr/local/ezyadmin
  cp -af ../agent /usr/local/ezyadmin/
  cp -f ezinstall_patch_mgr /usr/local/bin/ezinstall_patch_mgr
  echo "$DATE_NOW" > /usr/local/ezyadmin/agent/install
}

