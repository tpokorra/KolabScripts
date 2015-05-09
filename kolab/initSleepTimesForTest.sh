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
#reduce the sleep time between adding domains, see https://issues.kolab.org/show_bug.cgi?id=2491
#####################################################################################
sed -r -i -e "s/\[kolab\]/[kolab]\ndomain_sync_interval = 10/g" /etc/kolab/kolab.conf


# different paths in debian and centOS
pythonDistPackages=/usr/lib/python2.7/dist-packages
# Debian
if [ ! -d $pythonDistPackages ]; then
  # centOS
  pythonDistPackages=/usr/lib/python2.6/site-packages
  if [ ! -d $pythonDistPackages ]; then
    # centOS7
    pythonDistPackages=/usr/lib/python2.7/site-packages
  fi
fi

patch -p1 -i `pwd`/patches/sleepTimeDomainTests.patch -d $pythonDistPackages

if [ -f /bin/systemctl -a -f /etc/debian_version ]
then
  /bin/systemctl restart kolab-server
elif [ -f /bin/systemctl ]
then
  /bin/systemctl restart kolabd.service
elif [ -f /sbin/service ]
then
  service kolabd restart
elif [ -f /usr/sbin/service ]
then
  service kolab-server restart
fi
