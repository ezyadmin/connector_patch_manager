#!/usr/bin/env bash

#use
#./ezy_core.sh > ci_${HOSTNAME}.json && curl -H "Content-Type: application/json" -X POST --data-binary @ci.json http://192.168.100.80:8888/inventories/agent

#./ezy_core.sh > ezy_core.json
# curl -H "Content-Type: application/json" -X POST --data-binary @ci_cpdev1.rvglobalsoft.net.json http://192.168.100.80:8888/inventories/agent?org=551a483d973ce19219324585

#How to make yum show installed & latest packages (CentOS)

#TODO
#Notification incident

#http://arstechnica.com/civis/viewtopic.php?t=1081335

#get version
#http://unix.stackexchange.com/questions/54987/how-to-know-centos-version
 
#echo \"package name\",\"current version\",\"update version\"

#installl dependency
#cpan Linux::Distribution YAML

#================== function =============================
trim() {
    # Determine if 'extglob' is currently on.
    local extglobWasOff=1
    shopt extglob >/dev/null && extglobWasOff=0 
    (( extglobWasOff )) && shopt -s extglob # Turn 'extglob' on, if currently turned off.
    # Trim leading and trailing whitespace
    local var=$1
    var=${var##+([[:space:]])}
    var=${var%%+([[:space:]])}
    (( extglobWasOff )) && shopt -u extglob # If 'extglob' was off before, turn it back off.
    echo -n "$var"  # Output trimmed string.
}
#================== function =============================

#================== variable ========================
blank=""

OSNAME=`perl -e ' use Linux::Distribution qw(distribution_name distribution_version);  my $linux = Linux::Distribution->new;if(my $distro = $linux->distribution_name()) { my $version = $linux->distribution_version();print "$distro";}'`
# OSNAME=`perl get_os.pl`
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
	echo "Not support os : ${OSNAME}"
	exit;
fi

if [[ "${OSVERSION}" == "package centos-release is not installed" ]]
then
	OSVERSION=`cat /etc/redhat-release | tr '\n' ' ' | sed -e 's/[^\ +0-9\.]/ /g' -e 's/^ *//g' -e 's/ *$//g' | awk -F \. {'print $1'}`
fi

OSARCH=`uname -m`

ALLMONITORBY="[\"${OSNAME}${OSVERSION}\""

#if ["$OSVERSION"]; then
#  echo "CentOS"
#else
#  echo "not CentOS"
#fi

#yum -q check-update| while read i


CPNAME="none"
TIER=""

#==============cpanel================
FILE_Cpanel="/etc/cpupdate.conf"
if [ -f $FILE_Cpanel ];
then
	CPNAME="cpanel"
	TIER=`grep CPANEL /etc/cpupdate.conf`
	TIER=${TIER##*\=}
	
	CPVERSION=`/usr/local/cpanel/cpanel -V`
	
fi

#==============direct admin================
FILE_Da="/usr/local/directadmin/custombuild/build"
if [ -f $FILE_Da ];
then
	CPNAME="da"
	#TIER=`/usr/local/directadmin/custombuild/build versions | grep "Installed version of DirectAdmin"`
	#TIER=${TIER##*\:}
	#TIER=$(trim "${TIER}")
	TIER="stable"
fi


#=================general data===============
HOSTNAME=`hostname -f`
echo "{"
echo "\"agent\" : \"agent\","
echo "\"osarch\" : \"${OSARCH}\","
echo "\"osname\" : \"${OSNAME}\","
echo "\"hostname\" : \"${HOSTNAME}\","
echo "\"osversion\" : \"${OSVERSION}\","
echo "\"cpname\" : \"${CPNAME}\","
echo "\"tier\" : \"${TIER}\","

echo "\"ci\" : [ {} "

#========================yum==============================
<<COMMENT_YUM
#use inventory agent 
yum -q list installed | tr "\n" "#" | sed -e 's/# / /g' | tr "#" "\n"  | while read i
do
    i=$(echo $i) #this strips off yum's irritating use of whitespace
    if [ "${i}x" != "x" ]
    then
        UVERSION=${i#*\ }
        UVERSION=${UVERSION%\ *}
        PNAME=${i%%\ *}
        PNAME=${PNAME%.*}
        ARCH=${i%%\ *}
        ARCH=${ARCH##*.}
        FNAME=${i%%\ *}
        REPO=${i#*\ }
        REPO=${REPO#*\ }
        
        #clean version x:xx.xx
		if [[ $UVERSION == *":"* ]]
		then
			UVERSION=${UVERSION##*:}
		fi
		
        #echo "${REPOS}";
        #echo $(rpm -q "${PNAME}" --qf '"%{NAME}","%{VERSION}","')${UVERSION}\"
		echo ",{ \"name\" : \"${PNAME}\" ,  \"fullname\" : \"${FNAME}\" , \"latestversion\" : \"${UVERSION}\" , \"arch\" : \"${ARCH}\" , \"from\" : \"rpm\" ,\"repo\" : \"${REPO}\" , \"osname\" : \"${OSNAME}\", \"osversion\" : \"${OSVERSION}\", \"osarch\" : \"${OSARCH}\"} "
		#if [[ "${REPOS}" =~ ^(base|epel|extras|updates|@updates)$ ]]; then
			#	#echo "valid action"
		#fi
    fi
done
#echo "]"
COMMENT_YUM

#==============cpanel================
FILE_Cpanel="/etc/cpupdate.conf"
if [ -f $FILE_Cpanel ];
then	
	CPMonitorBy="cpanel_${TIER}"
	ALLMONITORBY="${ALLMONITORBY},\"${CPMonitorBy}\""
	CPManagedBy="cp"
	#cp version
	CP_VERSION=`cat /usr/local/cpanel/version`
	echo ",{ \"name\" : \"${CPNAME}\" ,  \"fullname\" : \"${CPNAME}\" , \"version\" : \"${CP_VERSION}\", \"monitorby\" : \"${CPMonitorBy}\", \"managedby\" : \"${CPManagedBy}\", \"cpname\" : \"cpanel\", \"cpversion\" : \"${TIER}\",  \"from\" : \"cpanel\" , \"osname\" : \"${OSNAME}\", \"osversion\" : \"${OSVERSION}\", \"osarch\" : \"${OSARCH}\"} "
	
	#easy apache
	EA_TEMP=`/usr/local/cpanel/bin/rebuild_phpconf --current | grep 'DEFAULT PHP: ea-php'`
	EA_TEMP=$(echo $EA_TEMP)
	EASYAPACHE_VERSION=""
	PHP_NAME="php"
	EASYAPACHE_NAME="easyapache"
	PHP_VERSION=""
	FTP_VERSION=""
	if [ "${EA_TEMP}x" != "x" ]; then
		EASYAPACHE_VERSION="4"
		
		#Get php version
		/usr/local/cpanel/bin/rebuild_phpconf --current | sed -e 's/^ea\-php+[0-9\.]/ /g' -e 's/^ *//g'  | awk -F \  {'print $1'} | while read eachPhp
		do
			eachPhp=$(echo $eachPhp)
			CK_FILE="/etc/scl/prefixes/${eachPhp}"
			if [ "${eachPhp}x" != "x" ] && [[ $eachPhp != DEFAULT ]]
			then
				PHP_VERSION=`scl enable $eachPhp 'php -v' | tr '\n' ' ' | sed -e 's/[^\ +0-9\.]/ /g' -e 's/^ *//g' | awk -F \  {'print $1'}`
				#echo "${eachPhp}=${PHP_VERSION}"
				PHP_DIS=${PHP_VERSION%.*}
				PHP_NAME="php$PHP_DIS"
				echo ",{ \"name\" : \"${PHP_NAME}\" ,  \"fullname\" : \"${PHP_NAME}\" , \"version\" : \"${PHP_VERSION}\", \"monitorby\" : \"${CPMonitorBy}\", \"managedby\" : \"${CPManagedBy}\", \"cpname\" : \"cpanel\" ,\"cpversion\" : \"${TIER}\",  \"from\" : \"cpanel\" , \"osname\" : \"${OSNAME}\", \"osversion\" : \"${OSVERSION}\", \"osarch\" : \"${OSARCH}\"} "
			fi
		done
		
	else
		EASYAPACHE_VERSION=`/usr/local/cpanel/scripts/easyapache --version | grep 'Easy Apache v' |  tr '\n' ' ' | sed -e 's/[^\+0-9\.]/ /g' -e 's/^ *//g'`
		PHP_VERSION=`php -v | tr '\n' ' ' | sed -e 's/[^\ +0-9\.]/ /g' -e 's/^ *//g' | awk -F \  {'print $1'}`
		
		PHP_DIS=${PHP_VERSION%.*}
		PHP_NAME="php$PHP_DIS"
		echo ",{ \"name\" : \"${PHP_NAME}\" ,  \"fullname\" : \"${PHP_NAME}\" , \"version\" : \"${PHP_VERSION}\", \"monitorby\" : \"${CPMonitorBy}\", \"managedby\" : \"${CPManagedBy}\", \"cpname\" : \"cpanel\" ,\"cpversion\" : \"${TIER}\",  \"from\" : \"cpanel\" , \"osname\" : \"${OSNAME}\", \"osversion\" : \"${OSVERSION}\", \"osarch\" : \"${OSARCH}\"} "
		
	fi
	#echo "EASYAPACHE_VERSION=${EASYAPACHE_VERSION}"
	#echo "PHP_VERSION=${PHP_VERSION}"
	echo ",{ \"name\" : \"${EASYAPACHE_NAME}\" ,  \"fullname\" : \"${EASYAPACHE_NAME}\" , \"version\" : \"${EASYAPACHE_VERSION}\", \"monitorby\" : \"${CPMonitorBy}\", \"managedby\" : \"${CPManagedBy}\", \"cpname\" : \"cpanel\" ,\"cpversion\" : \"${TIER}\",  \"from\" : \"cpanel\" , \"osname\" : \"${OSNAME}\", \"osversion\" : \"${OSVERSION}\", \"osarch\" : \"${OSARCH}\"} "
	
	#apache
	APACHE_VERSION=`httpd -v | tr '\n' ' ' | sed -e 's/[^\ +0-9\.]/ /g' -e 's/^ *//g' | awk -F \  {'print $1'}`
	APACHE_DIS=${APACHE_VERSION%.*}
	APACHE_NAME="apache$APACHE_DIS"
	#echo "APACHE_VERSION = ${APACHE_VERSION}"
	echo ",{ \"name\" : \"${APACHE_NAME}\" ,  \"fullname\" : \"${APACHE_NAME}\" , \"version\" : \"${APACHE_VERSION}\", \"monitorby\" : \"${CPMonitorBy}\", \"managedby\" : \"${CPManagedBy}\", \"cpname\" : \"cpanel\" ,\"cpversion\" : \"${TIER}\",  \"from\" : \"cpanel\" , \"osname\" : \"${OSNAME}\", \"osversion\" : \"${OSVERSION}\", \"osarch\" : \"${OSARCH}\"} "
	
	#ftp server
	FTP_NAME=`more  /var/cpanel/cpanel.config | grep ftpserver | awk -F \=  {'print $2'}`
	if [[ $FTP_NAME == pure\-ftpd ]] ; then
		FTP_VERSION=`pure-ftpd --help | head -1 | sed -e 's/[^\+0-9\.]/ /g' -e 's/^ *//g'`
	elif [[ $FTP_NAME == proftpd ]] ; then
		FTP_VERSION=`proftpd -v | sed -e 's/[^\+0-9\.]/ /g' -e 's/^ *//g'`
	fi
	
	echo ",{ \"name\" : \"${FTP_NAME}\" ,  \"fullname\" : \"${FTP_NAME}\" , \"version\" : \"${FTP_VERSION}\", \"monitorby\" : \"${CPMonitorBy}\", \"managedby\" : \"${CPManagedBy}\", \"cpname\" : \"cpanel\" ,\"cpversion\" : \"${TIER}\",  \"from\" : \"cpanel\" , \"osname\" : \"${OSNAME}\", \"osversion\" : \"${OSVERSION}\", \"osarch\" : \"${OSARCH}\"} "
	
	#mysql
	DB_NAME="MySQL"
	DB_VERSION=`mysql -V | sed -e 's/[^\+0-9\.]/ /g' -e 's/^ *//g' | awk -F \  {'print $2'}`
	DB_DIS=${DB_VERSION%.*}
	
	DB_NAME_CHECK=`mysql -V | grep -i mariadb`
	DB_NAME_CHECK=$(echo $DB_NAME_CHECK)
	if [ "${DB_NAME_CHECK}x" != "x" ]
	then
		DB_NAME="MariaDB"
	fi
	DB_NAME="$DB_NAME$DB_DIS"
	echo ",{ \"name\" : \"${DB_NAME}\" ,  \"fullname\" : \"${DB_NAME}\" , \"version\" : \"${DB_VERSION}\", \"monitorby\" : \"${CPMonitorBy}\", \"managedby\" : \"${CPManagedBy}\", \"cpname\" : \"cpanel\" ,\"cpversion\" : \"${TIER}\",  \"from\" : \"cpanel\" , \"osname\" : \"${OSNAME}\", \"osversion\" : \"${OSVERSION}\", \"osarch\" : \"${OSARCH}\"} "

	#SpamAssassin
	SPA_NAME="spamassassin"
	SPA_VERSION=`/usr/local/cpanel/3rdparty/bin/spamd -V | head -1 | sed -e 's/[^\+0-9\.]/ /g' -e 's/^ *//g'`
	echo ",{ \"name\" : \"${SPA_NAME}\" ,  \"fullname\" : \"${SPA_NAME}\" , \"version\" : \"${SPA_VERSION}\", \"monitorby\" : \"${CPMonitorBy}\", \"managedby\" : \"${CPManagedBy}\", \"cpname\" : \"cpanel\" ,\"cpversion\" : \"${TIER}\",  \"from\" : \"cpanel\" , \"osname\" : \"${OSNAME}\", \"osversion\" : \"${OSVERSION}\", \"osarch\" : \"${OSARCH}\"} "
	
fi
#===================direct admin==============================
if [[ "${CPNAME}" == "da" ]]; then
	CPMonitorBy="da_${TIER}"
	ALLMONITORBY="${ALLMONITORBY},\"${CPMonitorBy}\""
	CPManagedBy="cp"
	#ezyadmin_da = /usr/local/directadmin/custombuild/build versions
	/usr/local/directadmin/custombuild/build versions | while read ida
	do
		ida=$(echo $ida)
		
	    if [ "${ida}x" != "x" ] && [[ $ida == Installed\ version\ of* ]]
	    then
	    	#echo "ida = ${ida}";
	    	PKNAME=${ida#*Installed\ version\ of}
	    	PNAME=${PKNAME%%\:*}
	    	PNAME=$(trim "${PNAME}")
	    	PVERSION=${PKNAME##*\:}
	    	PVERSION=$(trim "${PVERSION}")
	    	#echo ${PNAME}
	    	#echo ${PVERSION}
	    	echo ",{ \"name\" : \"${PNAME}\" ,  \"fullname\" : \"${PNAME}\" , \"version\" : \"${PVERSION}\", \"monitorby\" : \"${CPMonitorBy}\", \"managedby\" : \"${CPManagedBy}\", \"cpname\" : \"da\" ,\"cpversion\" : \"${TIER}\",  \"from\" : \"da\" , \"osname\" : \"${OSNAME}\", \"osversion\" : \"${OSVERSION}\", \"osarch\" : \"${OSARCH}\"} "
	    fi
    done
	#echo "]"
fi

#==============cloudlinux================
#DETECTCLOUDLINUX=`uname -r | grep lve`
DETECTCLOUDLINUX=`yum list installed -d3 | grep "cloudlinux-release"`
#DETECTCLOUDLINUX=$(echo $DETECT_CLOUDLINUX)
CLOUNDLINUX_NAME=""
CLOUNDLINUX_MONITOR="cloudlinux"
if [ "${DETECTCLOUDLINUX}x" != "x" ]
then	
	#cloudlinux core : cloudlinux-release
	C_VERSION=`rpm -q --queryformat '%{VERSION}' cloudlinux-release`
	CLOUNDLINUX_NAME="CloudLinux$C_VERSION"
	CLOUNDLINUX_MONITOR="cloudlinux$C_VERSION"
	CLOUNDLINUX_VERSION=`rpm -q --queryformat '%{RELEASE}' cloudlinux-release`
	
	echo ",{ \"name\" : \"${CLOUNDLINUX_NAME}\" ,  \"fullname\" : \"${CLOUNDLINUX_NAME}\" , \"version\" : \"${CLOUNDLINUX_VERSION}\", \"monitorby\" : \"cloudlinux$C_VERSION\", \"managedby\" : \"cloudlinux\", \"cpname\" : \"${CPNAME}\" ,\"cpversion\" : \"${TIER}\",  \"from\" : \"cloudlinux\" , \"osname\" : \"${OSNAME}\", \"osversion\" : \"${OSVERSION}\", \"osarch\" : \"${OSARCH}\"} "
	
	#easy apache
	/usr/bin/cl-selector --list php | while read x y z
	
	
	do
		x=$(echo $x)
		y=$(echo $y)
		PHP_NAME="php${x}"
		PHP_VERSION="$y"
		echo ",{ \"name\" : \"${PHP_NAME}\" ,  \"fullname\" : \"${PHP_NAME}\" , \"version\" : \"${PHP_VERSION}\", \"monitorby\" : \"cloudlinux${C_VERSION}\", \"managedby\" : \"cloudlinux\", \"cpname\" : \"${CPNAME}\" ,\"cpversion\" : \"${TIER}\",  \"from\" : \"cloudlinux\" , \"osname\" : \"${OSNAME}\", \"osversion\" : \"${OSVERSION}\", \"osarch\" : \"${OSARCH}\"} "
	done

	#apache
	APACHE_VERSION=`httpd -v | tr '\n' ' ' | sed -e 's/[^\ +0-9\.]/ /g' -e 's/^ *//g' | awk -F \  {'print $1'}`
	APACHE_DIS=${APACHE_VERSION%.*}
	APACHE_NAME="apache$APACHE_DIS"
	#echo "APACHE_VERSION = ${APACHE_VERSION}"
	echo ",{ \"name\" : \"${APACHE_NAME}\" ,  \"fullname\" : \"${APACHE_NAME}\" , \"version\" : \"${APACHE_VERSION}\", \"monitorby\" : \"cloudlinux${C_VERSION}\", \"managedby\" : \"cloudlinux\", \"cpname\" : \"cpanel\" ,\"cpversion\" : \"${TIER}\",  \"from\" : \"cloudlinux\" , \"osname\" : \"${OSNAME}\", \"osversion\" : \"${OSVERSION}\", \"osarch\" : \"${OSARCH}\"} "
	
	#ftp server
	#FTP_NAME=`more  /var/cpanel/cpanel.config | grep ftpserver | awk -F \=  {'print $2'}`
	#if [[ $FTP_NAME == pure\-ftpd ]] ; then
		#	FTP_VERSION=`pure-ftpd --help | head -1 | sed -e 's/[^\+0-9\.]/ /g' -e 's/^ *//g'`
	#elif [[ $FTP_NAME == proftpd ]] ; then
		#	FTP_VERSION=`proftpd -v | sed -e 's/[^\+0-9\.]/ /g' -e 's/^ *//g'`
	#fi
	
	#echo ",{ \"name\" : \"${FTP_NAME}\" ,  \"fullname\" : \"${FTP_NAME}\" , \"latestversion\" : \"${FTP_VERSION}\", \"monitorby\" : \"cp\", \"cpname\" : \"cpanel\" ,\"cpversion\" : \"${TIER}\",  \"from\" : \"cpanel\" , \"osname\" : \"${OSNAME}\", \"osversion\" : \"${OSVERSION}\", \"osarch\" : \"${OSARCH}\"} "
	
	#mysql
	DB_VERSION=`mysql -V | sed -e 's/[^\+0-9\.]/ /g' -e 's/^ *//g' | awk -F \  {'print $2'}`
	DB_DIS=${DB_VERSION%.*}
	DB_NAME="mysql$DB_DIS"
	echo ",{ \"name\" : \"${DB_NAME}\" ,  \"fullname\" : \"${DB_NAME}\" , \"version\" : \"${DB_VERSION}\", \"monitorby\" : \"cloudlinux${C_VERSION}\", \"managedby\" : \"cloudlinux\", \"cpname\" : \"cpanel\" ,\"cpversion\" : \"${TIER}\",  \"from\" : \"cloudlinux\" , \"osname\" : \"${OSNAME}\", \"osversion\" : \"${OSVERSION}\", \"osarch\" : \"${OSARCH}\"} "

	#SpamAssassin
	#SPA_NAME="spamassassin"
	#SPA_VERSION=`/usr/local/cpanel/3rdparty/bin/spamd -V | head -1 | sed -e 's/[^\+0-9\.]/ /g' -e 's/^ *//g'`
	#echo ",{ \"name\" : \"${SPA_NAME}\" ,  \"fullname\" : \"${SPA_NAME}\" , \"latestversion\" : \"${SPA_VERSION}\", \"monitorby\" : \"cp\", \"cpname\" : \"cpanel\" ,\"cpversion\" : \"${TIER}\",  \"from\" : \"cpanel\" , \"osname\" : \"${OSNAME}\", \"osversion\" : \"${OSVERSION}\", \"osarch\" : \"${OSARCH}\"} "
	
fi

#===================3rdinstallation==============================
#==========pear============
#PEAR=`which pear`
#http://askubuntu.com/questions/29370/how-to-check-if-a-command-succeeded

#TMP_PEAR=""
TMP_PEAR=`which pear 2> /dev/null` || TMP_PEAR=$?
if [ "${TMP_PEAR}x" != "x" ] ; then
	ALLMONITORBY="${ALLMONITORBY},\"thirdparty_pear\""
	#echo "\"ci\" : [ {} "
	#pear list-all | tr "\n" "#" | sed -e 's/# / /g' | tr "#" "\n" | while read i j 
	#pear list | while read i j k
	eval "$TMP_PEAR list" | while read i j k
	do
		i=$(echo $i)
		j=$(echo $j)
		
		if [ "${i}x" != "x" ] && [ "${i}" != "INSTALLED" ]  && [ "${i}" != "PACKAGE" ] &&  [ "${j}x" != "x" ] && [[ $j =~ ^[0-9]{1} ]] ; then
	    	echo ",{\"name\":\"${i}\",\"fullname\":\"${i}\",\"version\":\"${j}\",\"from\":\"pear\",\"osname\":\"${OSNAME}\",\"osversion\":\"${OSVERSION}\",\"osarch\":\"${OSARCH}\",\"monitorby\":\"thirdparty_pear\" , \"managedby\":\"thirdparty\"}";
		fi
    done
    #echo "]"
fi
#==========cpan============
#which cpan
#TMP_CPAN=""
TMP_CPAN=`which cpan 2> /dev/null` || TMP_CPAN=$?
if [ "${TMP_CPAN}x" != "x" ] ; then
	ALLMONITORBY="${ALLMONITORBY},\"thirdparty_cpan\""
	#TODO Fix cpan run command is frist
	cpan -O | while read i j k
	do
		i=$(echo $i)
		j=$(echo $j)
		k=$(echo $k)
		
		if [ "${i}x" != "x" ] && [ "${i}" != "INSTALLED" ]  && [ "${i}" != "PACKAGE" ] &&  [ "${j}x" != "x" ] && [[ $j =~ ^[0-9]{1} ]] && [[ $k =~ ^[0-9]{1} ]] ; then
	    	echo ",{\"name\":\"${i}\",\"fullname\":\"${i}\",\"version\":\"${j}\",\"from\":\"cpan\",\"osname\":\"${OSNAME}\",\"osversion\":\"${OSVERSION}\",\"osarch\":\"${OSARCH}\",\"monitorby\":\"thirdparty_cpan\", \"managedby\":\"thirdparty\"}";
	    fi
    done
    #echo "]"
fi

#=================== kernel is not managed by yum =========================
KMANAGEDBY="package"
KEFFECTIVE_VERSION=`uname -r`
KEFFECTIVE_VERSION=${KEFFECTIVE_VERSION%.*}
KARCH=`uname -m`
K_VERSION=""
#kernel install last
#rpm -qa kernel | while read k
rpm -q kernel --qf "%{NAME}   %{VERSION}-%{RELEASE}\n" | while read k v
do
	k=$(echo $k)
	v=$(echo $v)
    if [ "${k}x" != "x" ] && [ "${v}x" != "x" ] ; then
    	K_VERSION="$v"
    	#echo ",{\"name\":\"${k}\",\"fullname\":\"${k}\",\"version\":\"${v}\",\"comments\":\"The Linux kernel\",\"from\":\"kernel\",\"osname\":\"${OSNAME}\",\"osversion\":\"${OSVERSION}\",\"osarch\":\"${OSARCH}\",\"monitorby\":\"kernel\"}"
    fi
done

#KernelCare =====================
Path_KernelCareCtl="/usr/bin/kcarectl"
if [ -f $Path_KernelCareCtl ];
then
	KMANAGEDBY="kernel"
	#SW_NAME="kernelcare"
	#SW_VERSION=`/usr/bin/kcarectl --version`
	#SW_COMMENT=`rpm -q --queryformat '%{SUMMARY}' kernelcare`
	#echo ",{\"name\":\"${SW_NAME}\",\"fullname\":\"${SW_NAME}\",\"version\":\"${SW_VERSION}\",\"comments\":\"${SW_COMMENT}\",\"from\":\"kernel\",\"osname\":\"${OSNAME}\",\"osversion\":\"${OSVERSION}\",\"osarch\":\"${OSARCH}\",\"monitorby\":\"kernel\"}"
	
	#KEFFECTIVE_VERSION=`/usr/bin/kcarectl --uname`
	KEFFECTIVE_VERSION=`kcarectl --uname`
fi

#Ksplice ===========================
KTMM=`rpm -q ksplice-uptrack-release --qf "%{NAME}"`
KTMM=$(echo $KTMM)
if [ "${KTMM}x" != "KTMM" ] && [ "${KTMM}" == "ksplice-uptrack-release" ]
then
	KMANAGEDBY="kernel"
	KEFFECTIVE_VERSION=`uptrack-uname -r`
fi	

KMONITORBY="${OSNAME}${OSVERSION}"
TestCloudLinux=$(echo $KEFFECTIVE_VERSION | grep lve)
if [ "${TestCloudLinux}x" != "x" ];then
	KMONITORBY="$CLOUNDLINUX_MONITOR"
fi	

#Effective kernel version
echo ",{\"name\":\"kernel\",\"fullname\":\"kernel.${KARCH}\",\"version\":\"${KEFFECTIVE_VERSION}\",\"effective_version\":\"${KEFFECTIVE_VERSION}\",\"lastupdate_version\":\"${K_VERSION}\",\"comments\":\"The Linux kernel\",\"from\":\"rpm\",\"osname\":\"${OSNAME}\",\"osversion\":\"${OSVERSION}\",\"osarch\":\"${OSARCH}\",\"monitorby\":\"${KMONITORBY}\",\"managedby\":\"${KMANAGEDBY}\"}"

#list software managed kernel
yum list installed | egrep 'uptrack|ksplice|kernelcare' | tr "\n" "#" | sed -e 's/# / /g' | tr "#" "\n"  | while read i
do
    i=$(echo $i) #this strips off yum's irritating use of whitespace
    if [ "${i}x" != "x" ]
    then
        UVERSION=${i#*\ }
        UVERSION=${UVERSION%\ *}
        PNAME=${i%%\ *}
        PNAME=${PNAME%.*}
        ARCH=${i%%\ *}
        ARCH=${ARCH##*.}
        FNAME=${i%%\ *}
        REPO=${i#*\ }
        REPO=${REPO#*\ }
        
        #clean version x:xx.xx
		if [[ $UVERSION == *":"* ]]
		then
			UVERSION=${UVERSION##*:}
		fi
		
		COMMENT=`rpm -q --queryformat '%{SUMMARY}' ${PNAME}`
		TKMONITORBY="${OSNAME}${OSVERSION}"
		echo ",{\"name\":\"${PNAME}\",\"fullname\":\"${FNAME}\",\"version\":\"${UVERSION}\",\"comments\":\"${COMMENT}\",\"from\":\"rpm\",\"osname\":\"${OSNAME}\",\"osversion\":\"${OSVERSION}\",\"osarch\":\"${OSARCH}\",\"monitorby\":\"${TKMONITORBY}\",\"managedby\":\"kernel\"}"
    fi
done


#===================end==============================
echo "],"

#=======================================exclude package for yum====================================
script -q -c "yum list installed -d3" ezytmp_yum.txt > /dev/null
echo "\"exclude\" : [ {} "
grep "\[31m" ezytmp_yum.txt | tr "\n" "#" | sed -e 's/# / /g' | tr "#" "\n" | while read i

do
	i=$(echo $i)
	if [ "${i}x" != "x" ] && [[ "$i" =~ \[31m ]]
    then
    	i=$(echo $i | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g")
        #UVERSION=${i#*\ }
        #UVERSION=${UVERSION%\ *}
        PNAME=${i%%\ *}
        PNAME=${PNAME%.*}
        #ARCH=${i%%\ *}
        #ARCH=${ARCH##*.}
        #FNAME=${i%%\ *}
        #REPO=${i#*\ }
        #REPO=${REPO#*\ }
		#echo ",{ \"name\" : \"${PNAME}\" ,  \"fullname\" : \"${FNAME}\" , \"latestversion\" : \"${UVERSION}\" , \"arch\" : \"${ARCH}\" , \"from\" : \"rpm\" ,\"repo\" : \"${REPO}\" , \"osname\" : \"${OSNAME}\", \"osversion\" : \"${OSVERSION}\", \"osarch\" : \"${OSARCH}\"} "
		echo ",{ \"name\" : \"${PNAME}\"} "
    fi
done
echo "],"
#===================end==============================

#================================== get all managedby===================================
echo "\"allmonitorby\" : ${ALLMONITORBY}]"
#================================== end get all managedby===============================
echo "}"
exit;