#!/bin/bash
# this script will remove Kolab, and DELETE all YOUR data!!!
# it will reinstall Kolab, from Kolab 3.1 Updates
# you can optionally install the patches from TBits, see bottom of script reinstall.sh

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

if [ -z `hostname -f | awk -F "." '{ print $2 }'` ]
then
  echo "FAILURE: please make sure you have configured a FQDN"
  echo
  echo
  exit 1
fi

service kolab-server stop
service kolab-saslauthd stop
service cyrus-imapd stop
service dirsrv stop
service wallace stop
service apache2 stop

if [ -f /usr/sbin/remove-ds-admin ]
then
  sed -i "s#/usr/lib/x86_64-linux-gnu/dirsrv/perl);#/usr/lib/x86_64-linux-gnu/dirsrv/perl);\nuse lib qw(/usr/lib/dirsrv/perl);#g" /usr/sbin/remove-ds-admin
  /usr/sbin/remove-ds-admin -f -a -y
fi

apt-get remove 389\* cyrus-imapd\* postfix\* mysql-server\* roundcube\* pykolab\* kolab\* libkolab\* kolab-3\*

# TODO problem reinstall? /etc/kolab/kolab.conf is gone after reinstall?
# rm -Rf /etc/kolab/kolab.conf

echo "deleting files..."
rm -Rf \
    /etc/postfix \
    /etc/dirsrv/slapd-* \
    /usr/lib64/dirsrv \
    /usr/share/kolab-webadmin \
    /usr/share/roundcubemail \
    /usr/share/kolab-syncroton \
    /usr/share/kolab \
    /usr/share/dirsrv \
    /usr/share/389-* \
    /var/cache/dirsrv \
    /var/cache/kolab-webadmin \
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

# could use environment variable obs=http://my.proxy.org/obs.kolabsys.com
# see http://kolab.org/blog/timotheus-pokorra/2013/11/26/downloading-obs-repo-php-proxy-file
if [[ "$obs" = "" ]]
then
  export obs=http://obs.kolabsys.com:82
fi

cat > /etc/apt/sources.list.d/kolab.list <<FINISH
deb $obs/Kolab:/3.1/$OBS_repo_OS/ ./
deb $obs/Kolab:/3.1:/Updates/$OBS_repo_OS/ ./
#deb $obs/Kolab:/Development/$OBS_repo_OS/ ./
#deb $obs/home:/tpokorra:/branches:/Kolab:/Development/$OBS_repo_OS/ ./
FINISH

wget $obs/Kolab:/3.1/$OBS_repo_OS/Release.key
apt-key add Release.key; rm -rf Release.key
wget $obs/Kolab:/3.1:/Updates/$OBS_repo_OS/Release.key
apt-key add Release.key; rm -rf Release.key
wget $obs/Kolab:/Development/$OBS_repo_OS/Release.key
apt-key add Release.key; rm -rf Release.key
wget $obs/home:/tpokorra:/branches:/Kolab:/Development/$OBS_repo_OS/Release.key
apt-key add Release.key; rm -rf Release.key

cat > /etc/apt/preferences.d/kolab <<FINISH
Package: *
Pin: origin obs.kolabsys.com
Pin-Priority: 501
FINISH

apt-get update
apt-get -y install aptitude
aptitude -y install kolab

