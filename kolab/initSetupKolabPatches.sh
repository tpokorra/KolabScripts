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
  # centOS
  pythonDistPackages=/usr/lib/python2.6/site-packages
fi

echo "applying setupkolab_yes_quietBug2598.patch to $pythonDistPackages/pykolab"
patch -p1 -i `pwd`/patches/setupkolab_yes_quietBug2598.patch -d $pythonDistPackages/pykolab
echo "applying setupkolab_directory_manager_pwdBug2645.patch"
patch -p1 -i `pwd`/patches/setupkolab_directory_manager_pwdBug2645.patch -d $pythonDistPackages

#####################################################################################
# make sure that kolab webadmin works even on my virtual machine with routed port 80
#####################################################################################
sed -r -i \
    -e '/api_url/d' \
    -e "s#\[kolab_wap\]#[kolab_wap]\napi_url = http://localhost/kolab-webadmin/api#g" \
    /etc/kolab/kolab.conf

