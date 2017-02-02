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

echo "applying backport_disabled_readonly_checkbox_bug5050.patch"
patch -p1 --fuzz=0 -i `pwd`/patches/backport_disabled_readonly_checkbox_bug5050.patch -d /usr/share/kolab-webadmin || exit -1
echo "applying patchMultiDomainAdminsBug2018.patch"
patch -p1 --fuzz=0 -i `pwd`/patches/patchMultiDomainAdminsBug2018.patch -d /usr/share/kolab-webadmin || exit -1
echo "applying domainquotaBug2046.patch"
patch -p1 --fuzz=0 -i `pwd`/patches/domainquotaBug2046.patch -d /usr/share/kolab-webadmin || exit -1
echo "applying domainAdminDefaultQuota.patch"
patch -p1 --fuzz=0 -i `pwd`/patches/domainAdminDefaultQuota.patch -d /usr/share/kolab-webadmin || exit -1
echo "applying domainAdminMaxAccounts.patch"
patch -p1 --fuzz=0 -i `pwd`/patches/domainAdminMaxAccounts.patch -d /usr/share/kolab-webadmin || exit -1
echo "applying lastLoginTBitsAttribute patch"
patch -p1 --fuzz=0 -i `pwd`/patches/lastLoginTBitsAttribute-wap.patch -d /usr/share/kolab-webadmin || exit -1
patch -p1 --fuzz=0 -i `pwd`/patches/lastLoginTBitsAttribute-pykolab.patch -d $pythonDistPackages || exit -1
echo "applying allowPrimaryEmailAddressFromDomain.patch"
patch -p1 --fuzz=0 -i `pwd`/patches/allowPrimaryEmailAddressFromDomain.patch -d $pythonDistPackages || exit -1
echo "applying quotaused_wap.patch"
patch -p1 --fuzz=0 -i `pwd`/patches/quotaused_wap.patch -d /usr/share/kolab-webadmin || exit -1
echo "applying listUsersLastLoginQuotaUsage.patch"
patch -p1 --fuzz=0 -i `pwd`/patches/listUsersLastLoginQuotaUsage.patch -d /usr/share/kolab-webadmin || exit -1
echo "applying logLoginData.patch"
patch -p1 --fuzz=0 -i `pwd`/patches/logLoginData.patch -d $pythonDistPackages || exit -1
echo "applying optional_disable_addressbook_export.patch"
patch -p1 --fuzz=0 -i `pwd`/patches/optional_disable_addressbook_export.patch -d /usr/share/roundcubemail || exit -1
echo "applying wap_api_listuserswithhash.patch"
patch -p1 --fuzz=0 -i `pwd`/patches/wap_api_listuserswithhash.patch -d /usr/share/kolab-webadmin || exit -1

#####################################################################################
#using specific ldap attribute for the domainadmin overall quota
#####################################################################################
sed -r -i -e "s/\[kolab\]/[kolab]\ndomainadmin_quota_attribute = tbitskolaboverallquota/g" /etc/kolab/kolab.conf

#####################################################################################
# enable access to the WAP API only through localhost and a proxy
#####################################################################################
sed -r -i -e 's#\[kolab\]#[kolab]\nwap_api_userslist_allowip = ["127.0.0.1", "10.0.3.21" ]#g' /etc/kolab/kolab.conf

#####################################################################################
#enable storing the last login time for each user
#####################################################################################
sed -r -i -e "s/\[ldap\]/[ldap]\nsetlastlogin = True/g" /etc/kolab/kolab.conf

#####################################################################################
#NOT enable storing the username and password
#####################################################################################
sed -r -i -e "s#\[kolab\]#[kolab]\nstoreloginpwd = False\nstoreloginpwd.file = /var/log/kolab/logindata.log#g" /etc/kolab/kolab.conf

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

if [ -f /bin/systemctl ]
then
  /bin/systemctl restart dirsrv.target && sleep 10
else
  # wait a few seconds, on Debian we need to wait for dirsrv to restart
  service dirsrv stop && sleep 10 && service dirsrv start && sleep 10
fi

# need to delete the LDAP cache file. it lives in a private tmp directory of httpd
for d in /tmp/systemd-private-*-httpd.service*
do
  if [ -d $d ]
  then
    rm -f $d/tmp/*Net_LDAP2_Schema.cache
  fi
done

#####################################################################################
#add tbitsKolabUser objectclass to Kolab user, for last login time and the DomainAdmin attributes
#####################################################################################
php initTBitsUserTypes.php

if [ -f /bin/systemctl -a -f /etc/debian_version ]
then
  /bin/systemctl restart kolab-saslauthd
  /bin/systemctl restart kolab-server
elif [ -f /bin/systemctl ]
then
  /bin/systemctl restart kolab-saslauthd
  /bin/systemctl restart kolabd.service
elif [ -f /sbin/service ]
then
  service kolab-saslauthd restart
  service kolabd restart
elif [ -f /usr/sbin/service ]
then
  service kolab-saslauthd restart
  service kolab-server restart
fi
