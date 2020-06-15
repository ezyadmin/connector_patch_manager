#!/usr/bin/env bash

echo "Parameter arg: $1"

# ========= variable ============
DATE_NOW=$(date '+%d/%m/%Y %H:%M:%S')
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
# echo "${red}red text ${green}green ${reset}text"

Check_Support()
{
  echo "${green}------------- Check support -------------${reset}"
  # TMP_YUM=`which yum 2> /dev/null` || TMP_YUM=$?
  TMP_YUM=`yum -v 2> /dev/null` || TMP_YUM=$?
  if [ "${TMP_YUM}x" == "x" ] || [ "${TMP_YUM}" == "127" ]; then
    echo "${red}Error : Operating system is not support.${reset}"
    exit;
  fi
  echo "${green}TMP_YUM ${TMP_YUM}="

  OSNAME=`perl ../agent/get_os.pl`
  OSVERSION=""
  if [[ "${OSNAME}" == "centos" ]] ;then
    OSNAME="CentOS"
    OSVERSION=`rpm -q --queryformat '%{VERSION}' centos-release`
  elif [[ "${OSNAME}" == "redhat" ]]; then
    OSNAME="RedHat"
    OSVERSION=`rpm -q --queryformat '%{VERSION}' epel-release`
  elif [[ "${OSNAME}" == "cloudlinux" ]]; then
    OSNAME="CloudLinux"
    OSVERSION=`rpm -q --queryformat '%{VERSION}' epel-release`
  else
    echo "${red}Error : Operating system is not support.${reset}"
    echo "${red}OS : ${OSNAME}${reset}"
    exit;
  fi
}

Install_Dependency()
{
  echo "${green}------------- Install dependency ------${reset}"
  mkdir -p /usr/local/ezyadmin/tmp/
  cd /usr/local/ezyadmin/tmp/
  yum -y install perl perl-devel perl-CPAN
  curl -L https://cpanmin.us | perl - App::cpanminus
  cpan YAML JSON Linux::Distribution
}

MAIN()
{
  echo "${green}------------- Main install ----------${reset}"
  mkdir -p /usr/local/ezyadmin/connector_patch_manager
  cd /usr/local/ezyadmin/connector_patch_manager
  # ===== check support ===
  
  # ===== copy ============
  cp -af ./agent /usr/local/ezyadmin/
  cp -af ./script /usr/local/ezyadmin/
  chmod 755 -R agent
  chmod 755 -R script

  EZBIN=/usr/local/bin/ezinstall_patch_mgr
  if [ ! -h $EZBIN ]; then
    echo "=> File doesn't exist"
    ln -s /usr/local/ezyadmin/connector_patch_manager/script/ezinstall_patch_mgr /usr/local/bin/ezinstall_patch_mgr
  fi
  echo "$DATE_NOW" > /usr/local/ezyadmin/connector_patch_manager/install.log
}

# ===== main process =====
Check_Support
Install_Dependency
Main
# ===== main process =====
