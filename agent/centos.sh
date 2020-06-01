#!/bin/bash

#use

#How to make yum show installed & latest packages (CentOS)

#TODO

#http://arstechnica.com/civis/viewtopic.php?t=1081335

#get version
 
#echo \"package name\",\"current version\",\"update version\"

OSNAME="CentOS"
OSVERSION=`rpm -q --queryformat '%{VERSION}' centos-release`
OSARCH=`uname -m`

#if ["$OSVERSION"]; then

#yum -q check-update| while read i

echo "{"
echo "\"osarch\" : \"${OSARCH}\","
echo "\"osname\" : \"${OSNAME}\","
echo "\"osversion\" : \"${OSVERSION}\","
echo "\"ci\" : [ {} "

yum -q list all | tr "\n" "#" | sed -e 's/# / /g' | tr "#" "\n"  | while read i


do
    i=$(echo $i) #this strips off yum's irritating use of whitespace
	#echo "i = ${i}";
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
        #echo "${REPOS}";
        #echo $(rpm -q "${PNAME}" --qf '"%{NAME}","%{VERSION}","')${UVERSION}\"
		echo ",{ \"name\" : \"${PNAME}\" ,  \"fullname\" : \"${FNAME}\" , \"latestversion\" : \"${UVERSION}\" , \"arch\" : \"${ARCH}\" , \"from\" : \"rpm\" ,\"repo\" : \"${REPO}\" , \"osname\" : \"${OSNAME}\", \"osversion\" : \"${OSVERSION}\", \"osarch\" : \"${OSARCH}\"} "
		#if [[ "${REPOS}" =~ ^(base|epel|extras|updates|@updates)$ ]]; then
			#	#echo "valid action"
		#fi
    fi
done
echo "]}"

#yum install -y yum-utils

