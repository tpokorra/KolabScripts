#!/bin/bash

# Install Patch and wget if not installed
yum -y install wget patch

#####################################################################################
# apply a couple of patches, see related kolab bugzilla number in filename, eg. https://issues.kolab.org/show_bug.cgi?id=1869
#####################################################################################

# fixes for pykolab 0.6.8 and kolab-webadmin 3.1.0 
# fixes ldap aci creating during setup and when adding new domains

if [ ! -d patches ]
then
  mkdir -p patches
  echo Downloading patch  patchFixLDAPAci-01-2514.patch
  wget https://raw.github.com/dhoffend/kolab3_tbits_scripts/master/kolab3.1/patches/patchFixLDAPAci-01-2514.patch -O patches/patchFixLDAPAci-01-2514.patch
  echo Downloading patch  patchFixLDAPAci-02-2514.patch
  wget https://raw.github.com/dhoffend/kolab3_tbits_scripts/master/kolab3.1/patches/patchFixLDAPAci-02-2514.patch -O patches/patchFixLDAPAci-02-2514.patch

fi

patch -p1 -i `pwd`/patches/patchFixLDAPAci-01-2514.patch -d /usr/lib/python2.6/site-packages
patch -p1 -i `pwd`/patches/patchFixLDAPAci-02-2514.patch -d /usr/share/kolab-webadmin
