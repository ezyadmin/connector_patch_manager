#!/bin/sh

mkdir -p /usr/local/ezyadmin
cd /usr/local/ezyadmin
wget -O connector_patch_manager.tar.gz https://github.com/ezyadmin/connector_patch_manager/archive/latest.tar.gz
tar -xzf connector_patch_manager.tar.gz
cd connector_patch_manager-latest/install
chmod 755 install.sh
./install.sh