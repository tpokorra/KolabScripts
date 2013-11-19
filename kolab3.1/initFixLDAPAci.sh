#!/bin/bash

# Install Patch and wget if not installed
if ( which yum ); then
  yum -y install wget patch
else
  if (which apt-get); then
    apt-get -y install wget patch;
  else echo "Neither yum nor apt-get available. On which platform are you?";
  exit 0
  fi
fi

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

# different paths in debian and centOS
# centOS
pythonDistPackages=/usr/lib/python2.7/dist-packages
if [ ! -d $pythonDistPackages ]; then
  # Debian
  pythonDistPackages=/usr/lib/python2.6/site-packages
fi

patch -p1 -i `pwd`/patches/patchFixLDAPAci-01-2514.patch -d $pythonDistPackages
patch -p1 -i `pwd`/patches/patchFixLDAPAci-02-2514.patch -d /usr/share/kolab-webadmin
