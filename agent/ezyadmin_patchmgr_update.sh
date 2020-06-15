#!/bin/sh
##!/bin/bash
#
#0 1 * * * perl -le 'sleep rand 9000' && /usr/local/ezyadmin/agent/ezyadmin_patchmgr_update.sh
<<"Config_Patch"
package :
  - yum
  - cpan
  - pear
  - cloudlinux
  - kernel
  - source
schedule : 
  - every : time
  - from : 01:00
  - to : 02:00

Config_Patch

#====================== function ===================================
function parse_yaml() {
    local prefix=$2
    local s
    local w
    local fs
    s='[[:space:]]*'
    w='[a-zA-Z0-9_]*'
    fs="$(echo @|tr @ '\034')"
    sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" "$1" |
    awk -F"$fs" '{
    indent = length($1)/2;
    vname[indent] = $2;
    for (i in vname) {if (i > indent) {delete vname[i]}}
        if (length($3) > 0) {
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
            printf("%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, $3);
        }
    }' | sed 's/_=/+=/g'
}

#====================== main========================================
file="/usr/local/ezyadmin/agent/schedule.yaml"
watchfile="/usr/local/ezyadmin/agent/watch"
echo "$(date)" >> $watchfile

if [ -f "$file" ]
then
	echo "Found config : ${file}"
    #echo "$0: File '${file}' not found."
    #eval $(parse_yaml /usr/local/ezyadmin/agent/schedule.yaml "config_")
    
    eval $(parse_yaml /usr/local/ezyadmin/agent/schedule.yaml "config_")
    #echo $config_package[@];
    #echo "${config_package[@]}"
    for packageName in "${config_package[@]}"
    do
    	:
    	# do whatever on $i
    	echo "Automatic update package from : $packageName"
    	case "$packageName" in
			"yum") echo "Check yum command"
				if which yum >/dev/null; then
					echo "call command line : yum -y update"
				    yum -y update
				else
				    echo "yum command not found"
				fi
			;;
			"cpan") echo "Check cpan command"
				if which cpan >/dev/null; then
					echo "perl -MCPAN -e \"upgrade /(.\*)/\""
				    perl -MCPAN -e "upgrade /(.\*)/"
				else
				    echo "cpan command not found"
				fi
			;;
			"pear") echo "Check pear command"
				if which pear >/dev/null; then
					echo "pear install PEAR"
					echo "pear install PEAR"
				    pear install PEAR
				    pear upgrade-all
				else
				    echo "pear command not found"
				fi
			;;
			"cloudlinux") echo "Check cloudlinux os"
				if which uname -r | grep lve 2>/dev/null; then
					echo "yum clean all --enablerepo=cloudlinux-updates-testing"
					echo "yum update --enablerepo=cloudlinux-updates-testing"
				    yum clean all --enablerepo=cloudlinux-updates-testing
				    yum update --enablerepo=cloudlinux-updates-testing
				else
				    echo "pear command not found"
				fi
			;;
			"kernel") echo "Check kernel managed by another software."
				FOUND_MANAND_KERNEL =0;
				yum list installed | egrep 'uptrack|ksplice|kernelcare' | tr "\n" "#" | sed -e 's/# / /g' | tr "#" "\n"  | while read i
				do
				    i=$(echo $i)
				    if [ "${i}x" != "x" ]
				    then
				        FOUND_MANAND_KERNEL = 1;
				    fi
				done
				if FOUND_MANAND_KERNEL ; then
					echo "yum clean all --enablerepo=cloudlinux-updates-testing"
					echo "yum update --enablerepo=cloudlinux-updates-testing"
				    
				    #KernelCare =====================
					Path_KernelCareCtl="/usr/bin/kcarectl"
					if [ -f $Path_KernelCareCtl ];
					then
						echo "kernel managed by KernelCare"
						KEFFECTIVE_VERSION=`kcarectl --uname`
						echo "kernel effective version"
						echo KEFFECTIVE_VERSION
						
						/usr/bin/kcarectl --update
						KAEFFECTIVE_VERSION=`kcarectl --uname`
						echo "kernel effective version after update"
						echo KAEFFECTIVE_VERSION
					fi
					
					#Ksplice ===========================
					KTMM=`rpm -q ksplice-uptrack-release --qf "%{NAME}"`
					KTMM=$(echo $KTMM)
					if [ "${KTMM}x" != "KTMM" ] && [ "${KTMM}" == "ksplice-uptrack-release" ]
					then
						echo "kernel managed by Ksplice"
						KEFFECTIVE_VERSION=`uptrack-uname -r`
						echo "kernel effective version"
						echo KEFFECTIVE_VERSION
						
						uptrack-upgrade -y
						KAEFFECTIVE_VERSION=`uptrack-uname -r`
						echo "kernel effective version after update"
						echo KAEFFECTIVE_VERSION
					fi	
					
					#Test
					#TestCloudLinux=$(echo $KEFFECTIVE_VERSION | grep lve)
					#if [ "${TestCloudLinux}x" != "x" ];then
					#	echo "TestCloudLinux ok";
					#fi

				else
				    echo "pear command not found"
				fi
			;;
			"source") echo "#TODO Compile  from source" 
			;;
		esac
    done
else
	echo "File config not found!!! in /usr/local/ezyadmin/agent/schedule.yaml"
fi