#!/bin/bash

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

DetermineOS
InstallWgetAndPatch
DeterminePythonPath

#####################################################################################
#reduce the sleep time between adding domains, see https://issues.kolab.org/show_bug.cgi?id=2491
#####################################################################################
sed -r -i -e "s/\[kolab\]/[kolab]\ndomain_sync_interval = 10/g" /etc/kolab/kolab.conf

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
