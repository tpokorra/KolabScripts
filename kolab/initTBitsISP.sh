#!/bin/bash

if [ `which yum` ]; then
  if [[ ! `which wget` || ! `which patch` ]]; then
    yum -y install wget patch
  fi
else
  if [ `which apt-get` ]; then
    if [[ ! `which wget` || ! `which patch` ]]; then
      apt-get -y install wget patch;
    fi
  else echo "Neither yum nor apt-get available. On which platform are you?";
  exit 0
  fi
fi

#####################################################################################
# apply a couple of patches, see related kolab bugzilla number in filename, eg. https://issues.kolab.org/show_bug.cgi?id=2018
#####################################################################################
# different paths in debian and centOS
pythonDistPackages=/usr/lib/python2.7/dist-packages
# Debian
if [ ! -d $pythonDistPackages ]; then
  # centOS6
  pythonDistPackages=/usr/lib/python2.6/site-packages
  if [ ! -d $pythonDistPackages ]; then
    # centOS7
    pythonDistPackages=/usr/lib/python2.7/site-packages
  fi
fi

echo "applying patchMultiDomainAdminsBug2018.patch"
patch -p1 -i `pwd`/patches/patchMultiDomainAdminsBug2018.patch -d /usr/share/kolab-webadmin || exit -1
echo "applying domainquotaBug2046.patch"
patch -p1 -i `pwd`/patches/domainquotaBug2046.patch -d /usr/share/kolab-webadmin || exit -1
echo "applying domainAdminDefaultQuota.patch"
patch -p1 -i `pwd`/patches/domainAdminDefaultQuota.patch -d /usr/share/kolab-webadmin || exit -1
echo "applying domainAdminMaxAccounts.patch"
patch -p1 -i `pwd`/patches/domainAdminMaxAccounts.patch -d /usr/share/kolab-webadmin || exit -1
echo "applying lastLoginTBitsAttribute patch"
patch -p1 -i `pwd`/patches/lastLoginTBitsAttribute-wap.patch -d /usr/share/kolab-webadmin || exit -1
patch -p1 -i `pwd`/patches/lastLoginTBitsAttribute-pykolab.patch -d $pythonDistPackages || exit -1
echo "applying allowPrimaryEmailAddressFromDomain.patch"
patch -p1 -i `pwd`/patches/allowPrimaryEmailAddressFromDomain.patch -d $pythonDistPackages || exit -1

#####################################################################################
#using specific ldap attribute for the domainadmin overall quota
#####################################################################################
sed -r -i -e "s/\[kolab\]/[kolab]\ndomainadmin_quota_attribute = tbitskolaboverallquota/g" /etc/kolab/kolab.conf


#####################################################################################
#enable storing the last login time for each user
#####################################################################################
sed -r -i -e "s/\[ldap\]/[ldap]\nsetlastlogin = True/g" /etc/kolab/kolab.conf


#####################################################################################
#disable LDAP debugging
#####################################################################################
sed -r -i -e 's/config_set\("debug", true\)/config_set("debug", false)/g' /usr/share/kolab-webadmin/lib/Auth/LDAP.php


#####################################################################################
#extend the LDAP schema for TBits ISP patches
#####################################################################################
for d in /etc/dirsrv/slapd*
do
  cp patches/99tbits.ldif $d/schema/
done

service dirsrv restart
# wait a few seconds, on Debian we need to wait for dirsrv to restart
sleep 20


#####################################################################################
#create new user_type domainadmin
#add tbitsKolabUser objectclass to Kolab user, for last login time
#####################################################################################
php initTBitsUserTypes.php

service kolab-saslauthd restart

if [ -f /bin/systemctl ]
then
  /bin/systemctl restart kolabd.service
elif [ -f /sbin/service ]
then
  service kolabd restart
elif [ -f /usr/sbin/service ]
then
  service kolab-server restart
fi
