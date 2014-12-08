#!/bin/bash

dist="unknown"
if [ `which yum` ]; then
  dist="CentOS"
  if [[ ! `which wget` || ! `which patch` ]]; then
    yum -y install wget patch
  fi
else
  if [ `which apt-get` ]; then
    dist="Debian"
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
# Debian
pythonDistPackages=/usr/lib/python2.7/dist-packages
if [ ! -d $pythonDistPackages ]; then
  # centOS6
  pythonDistPackages=/usr/lib/python2.6/site-packages
  if [ ! -d $pythonDistPackages ]; then
    # centOS7
    pythonDistPackages=/usr/lib/python2.7/site-packages
  fi
fi

echo "applying setupkolab_yes_quietBug2598.patch to $pythonDistPackages/pykolab"
patch -p1 -i `pwd`/patches/setupkolab_yes_quietBug2598.patch -d $pythonDistPackages/pykolab
echo "applying setupkolab_directory_manager_pwdBug2645.patch"
patch -p1 -i `pwd`/patches/setupkolab_directory_manager_pwdBug2645.patch -d $pythonDistPackages

echo "temporary fixes for Cyrus stop script"
patch -p0 -i `pwd`/patches/fixcyrusstop.patch
echo "applying kolabsyncBug3975.patch to $pythonDistPackages/pykolab"
patch -p2 -i `pwd`/patches/kolabsyncBug3975.patch -d $pythonDistPackages/pykolab

# temporary patch, should go upstream soon
patch -p1 -i `pwd`/patches/addSharedFolderBug4043.patch -d /usr/share/kolab-webadmin
