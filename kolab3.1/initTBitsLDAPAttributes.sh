#!/bin/bash

#####################################################################################
# patch the LDAP schema for TBits extensions for ISP support (domain admin overall quota, maxAccounts, etc)
#####################################################################################
yum -y install wget patch

if [ ! -d patches ]
then
  mkdir -p patches
  echo Downloading patch patchTBitsLDAPAttributes.patch...
  wget https://raw.github.com/tpokorra/kolab3_tbits_scripts/master/kolab3.1/patches/patchTBitsLDAPAttributes.patch -O patches/patchTBitsLDAPAttributes.patch
fi

patch -p0 -i `pwd`/patches/patchTBitsLDAPAttributes.patch

