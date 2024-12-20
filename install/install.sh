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
  # echo "${green}TMP_YUM ${TMP_YUM}="

  OSNAME=`perl /usr/local/ezyadmin/connector_patch_manager-latest/agent/get_os.pl`
  OSVERSION=""
  if [[ "${OSNAME}" == "centos" ]] ;then
    OSNAME="CentOS"
    OSVERSION=`rpm -q --queryformat '%{VERSION}' centos-release | awk -F. '{print $1}' | tr -d "\n"`
  elif [[ "${OSNAME}" == "redhat" ]]; then
    OSNAME="RedHat"
    OSVERSION=`rpm -q --queryformat '%{VERSION}' epel-release | awk -F. '{print $1}' | tr -d "\n"`
  elif [[ "${OSNAME}" == "cloudlinux" ]]; then
    OSNAME="CloudLinux"
    OSVERSION=`rpm -q --queryformat '%{VERSION}' epel-release | awk -F. '{print $1}' | tr -d "\n"`
  elif [[ "${OSNAME}" == "almalinux" ]]; then
    OSNAME="almalinux"
    OSVERSION=`rpm -q --queryformat '%{VERSION}' epel-release | awk -F. '{print $1}' | tr -d "\n"`
  else
    echo "${red}Error : Operating system is not support.${reset}"
    echo "${red}OS : ${OSNAME}${reset}"
    exit;
  fi
  echo "${green}OS : ${OSNAME}${reset}"
  echo "${green}Version : ${OSVERSION}${reset}"

}

Install_Dependency()
{
  echo "${green}------------- Install dependency ------${reset}"
  mkdir -p /usr/local/ezyadmin/tmp/
  cd /usr/local/ezyadmin/tmp/
  yum -y install perl perl-devel perl-CPAN cpanminus
  curl -L https://cpanmin.us | perl - App::cpanminus
  PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'my $c = "CPAN::HandleConfig"; $c->load(doit => 1, autoconfig => 1); $c->edit(prerequisites_policy => "follow"); $c->edit(build_requires_install_policy => "yes"); $c->commit'
  # cpan YAML JSON Linux::Distribution
  cpanm YAML JSON Linux::Distribution
}

Main_Install()
{
  echo "${green}------------- Main install ----------${reset}"
  # install path
  mkdir -p /usr/local/ezyadmin/connector_patch_manager-latest
  # default path
  mkdir -p /usr/local/ezyadmin/connector_patch_manager
  # cp -af ./../connector_patch_manager-latest /usr/local/ezyadmin/connector_patch_manager
  cd /usr/local/ezyadmin/connector_patch_manager-latest
  # ===== check support ===
  
  # ===== copy ============
  cp -af ./agent /usr/local/ezyadmin/
  cp -af ./script /usr/local/ezyadmin/
  chmod 755 -R agent
  chmod 755 -R script

  EZBIN=/usr/local/bin/ezinstall_patch_mgr
  if [ ! -e $EZBIN ]; then
    echo "=> create symbolic"
    ln -sf /usr/local/ezyadmin/connector_patch_manager-latest/script/ezinstall_patch_mgr /usr/local/bin/ezinstall_patch_mgr
    # default file connector_patch_manager-latest
    # FILE=/usr/local/ezyadmin/connector_patch_manager-latest/script/ezinstall_patch_mgr
    # if test -f "$FILE"; then
    #     ln -sf /usr/local/ezyadmin/connector_patch_manager-latest/script/ezinstall_patch_mgr /usr/local/bin/ezinstall_patch_mgr
    # fi

    # dir connector_patch_manager
    # FILE=/usr/local/ezyadmin/connector_patch_manager/script/ezinstall_patch_mgr
    # if test -f "$FILE"; then
    #     ln -s /usr/local/ezyadmin/connector_patch_manager/script/ezinstall_patch_mgr /usr/local/bin/ezinstall_patch_mgr
    # fi

    # ln -s /usr/local/ezyadmin/connector_patch_manager/script/ezinstall_patch_mgr /usr/local/bin/ezinstall_patch_mgr
  fi
  echo "$DATE_NOW" > /usr/local/ezyadmin/connector_patch_manager/install.log
  echo "${green}------------- Done, Installed ----------${reset}"
}

# ===== main process =====
Check_Support
Install_Dependency
Main_Install
# ===== main process =====
