#!/bin/bash

#####################################################################################
# apply a couple of patches, see related kolab bugzilla number in filename, eg. https://issues.kolab.org/show_bug.cgi?id=2018
#####################################################################################
yum -y install wget patch

if [ ! -d patches ]
then
  echo Downloading patch checkboxLDAPBug2452.patch
  wget https://raw.github.com/tpokorra/kolab3_tbits_scripts/master/kolab3.1/patches/checkboxLDAPBug2452.patch -O patches/checkboxLDAPBug2452.patch
  echo Downloading patch patchDomainAdminAccountLimitations.patch
  wget https://raw.github.com/tpokorra/kolab3_tbits_scripts/master/kolab3.1/patches/patchDomainAdminAccountLimitations.patch -O patches/patchDomainAdminAccountLimitations.patch
fi

patch -p0 -i `pwd`/patches/checkboxLDAPBug2452.patch
patch -p0 -i `pwd`/patches/patchDomainAdminAccountLimitations.patch

#####################################################################################
#create new user_type domainadmin
#####################################################################################
php initDomainAdminType.php

#####################################################################################
#using specific ldap attribute for the domainadmin overall quota
#####################################################################################
sed -r -i -e "s/\[kolab\]/[kolab]\ndomainadmin_quota_attribute = tbitskolaboverallquota/g" /etc/kolab/kolab.conf


