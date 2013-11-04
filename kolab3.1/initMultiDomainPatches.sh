#!/bin/bash

#####################################################################################
# apply a couple of patches, see related kolab bugzilla number in filename, eg. https://issues.kolab.org/show_bug.cgi?id=2018
#####################################################################################
if [ ! -d patches ]
then
  mkdir -p patches
  echo Downloading patch patchMultiDomainAdminsBug2018.patch...
  wget https://raw.github.com/tpokorra/kolab3_tbits_scripts/master/kolab3.1/patches/patchMultiDomainAdminsBug2018.patch -O patches/patchMultiDomainAdminsBug2018.patch
  echo Downloading patch domainquotaBug2046.patch...
  wget https://raw.github.com/tpokorra/kolab3_tbits_scripts/master/kolab3.1/patches/domainquotaBug2046.patch -O patches/domainquotaBug2046.patch
  echo Downloading patch  deleteDomainWithUsersBug1869.patch
  wget https://raw.github.com/tpokorra/kolab3_tbits_scripts/master/kolab3.1/patches/deleteDomainWithUsersBug1869.patch -O patches/deleteDomainWithUsersBug1869.patch
  echo Downloading patch checkboxLDAPBug2452.patch
  wget https://raw.github.com/tpokorra/kolab3_tbits_scripts/master/kolab3.1/patches/checkboxLDAPBug2452.patch -O patches/checkboxLDAPBug2452.patch
  echo Downloading patch patchDomainAdminAccountLimitations.patch
  wget https://raw.github.com/tpokorra/kolab3_tbits_scripts/master/kolab3.1/patches/patchDomainAdminAccountLimitations.patch -O patches/patchDomainAdminAccountLimitations.patch
fi

patch -p1 -i `pwd`/patches/patchMultiDomainAdminsBug2018.patch -d /usr/share/kolab-webadmin
patch -p1 -i `pwd`/patches/domainquotaBug2046.patch -d /usr/share/kolab-webadmin
patch -p1 -i `pwd`/patches/deleteDomainWithUsersBug1869.patch -d /usr/share/kolab-webadmin
patch -p0 -i `pwd`/patches/checkboxLDAPBug2452.patch
patch -p0 -i `pwd`/patches/patchDomainAdminAccountLimitations.patch
