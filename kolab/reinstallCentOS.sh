#!/bin/bash
# this script will remove Kolab, and DELETE all YOUR data!!!
# it will reinstall Kolab, from Kolab 3.4 Updates and Kolab Development
# you can optionally install the patches from TBits, see bottom of script reinstall.sh

#check that dirsrv will have write permissions to /dev/shm
if [[ $(( `stat --format=%a /dev/shm` % 10 & 2 )) -eq 0 ]]
then
	# it seems that group also need write access, not only other; therefore a+w
	echo "please run: chmod a+w /dev/shm"
	exit 1
fi

if [[ "`sestatus | grep disabled`" == "" ]];
then
	echo "SELinux is active, please disable SELinux first"
        exit 1
fi

echo "this script will remove Kolab, and DELETE all YOUR data!!!"
read -p "Are you sure? Type y or Ctrl-C " -r
echo 
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

if [ -z $1 ]
then
  echo "please call $0 <distribution version as on OBS>"
  exit 1
fi
OBS_repo_OS=$1

service kolabd stop
service kolab-saslauthd stop
service cyrus-imapd stop
service dirsrv stop
service wallace stop
service httpd stop

yum -y remove 389\* cyrus-imapd\* postfix\* mysql-server\* roundcube\* pykolab\* kolab\* libkolab\* libcalendaring\* kolab-3\* httpd php-Net-LDAP3 up-imapproxy nginx stunnel

echo "deleting files..."
rm -Rf \
    /etc/dirsrv \
    /etc/kolab \
    /etc/postfix \
    /etc/pki/tls/private/example* \
    /etc/pki/tls/certs/example* \
    /etc/roundcubemail \
    /usr/lib64/dirsrv \
    /usr/share/kolab-webadmin \
    /usr/share/roundcubemail \
    /usr/share/kolab-syncroton \
    /usr/share/kolab \
    /usr/share/dirsrv \
    /var/cache/dirsrv \
    /var/cache/kolab-webadmin \
    /var/lock/dirsrv \
    /var/log/kolab* \
    /var/log/dirsrv \
    /var/log/roundcube \
    /var/log/maillog \
    /var/lib/dirsrv \
    /var/lib/imap \
    /var/lib/kolab \
    /var/lib/mysql \
    /tmp/*-Net_LDAP2_Schema.cache \
    /var/spool/imap \
    /var/spool/postfix

/etc/init.d/rsyslog restart

yum -y install epel-release yum-utils

# could use environment variable obs=http://my.proxy.org/obs.kolabsys.com 
# see http://kolab.org/blog/timotheus-pokorra/2013/11/26/downloading-obs-repo-php-proxy-file
if [[ "$obs" = "" ]]
then
  export obs=http://obs.kolabsys.com/repositories/
fi

rm -f /etc/yum.repos.d/Kolab*.repo /etc/yum.repos.d/lbs-tbits.net-kolab-nightly.repo
yum-config-manager --add-repo $obs/Kolab:/3.4/$OBS_repo_OS/Kolab:3.4.repo
yum-config-manager --add-repo $obs/Kolab:/3.4:/Updates/$OBS_repo_OS/Kolab:3.4:Updates.repo
yum-config-manager --add-repo $obs/Kolab:/Development/$OBS_repo_OS/Kolab:Development.repo

# install key http://keyserver.ubuntu.com/pks/lookup?op=vindex&search=devel%40lists.kolab.org&fingerprint=on
rpm --import "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x830C2BCF446D5A45"

# add priority = 0 to kolab repo files
for f in /etc/yum.repos.d/Kolab*.repo
do
    sed -i "s#enabled=1#enabled=1\npriority=0#g" $f
    sed -i "s#http://obs.kolabsys.com:82/#$obs/#g" $f
done

yum clean metadata

tryagain=0
yum -y install kolab kolab-freebusy patch unzip || tryagain=1
if [ $tryagain -eq 1 ]; then
  yum clean metadata
  yum -y install kolab kolab-freebusy patch unzip
fi

