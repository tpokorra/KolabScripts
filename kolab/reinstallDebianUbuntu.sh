#!/bin/bash
# this script will remove Kolab, and DELETE all YOUR data!!!
# it will reinstall Kolab, from Kolab 16
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

if [[ $OBS_repo_OS == "Debian_7.0" ]]
then
  LBS_repo_OS="debian/wheezy wheezy"
elif [[ $OBS_repo_OS == "Debian_8.0" ]]
then
  LBS_repo_OS="debian/jessie jessie"
elif [[ $OBS_repo_OS == "Ubuntu_14.04" ]]
then
  LBS_repo_OS="ubuntu/trusty trusty"
fi

if [ -z `hostname -f | awk -F "." '{ print $2 }'` ]
then
  echo "FAILURE: please make sure you have configured a FQDN"
  echo
  echo
  exit 1
fi

# install locale to avoid problems like:
# Please check that your locale settings:
#	LANGUAGE = (unset),
#	LC_ALL = (unset),
#	LANG = "en_US.UTF-8"
#    are supported and installed on your system.
debconf-set-selections <<< 'locales	locales/locales_to_be_generated	multiselect	en_US.UTF-8 UTF-8'
debconf-set-selections <<< 'locales	locales/default_environment_locale	select	en_US.UTF-8'
export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
dpkg-reconfigure locales

# make sure that mysql installs noninteractively
# to get these values: apt-get install mysql-server && apt-get install debconf-utils && debconf-get-selections | grep mysql
debconf-set-selections <<< 'mysql-server-5.5	mysql-server/root_password_again	password'
debconf-set-selections <<< 'mysql-server-5.5	mysql-server/root_password	password'

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

apt-get -y purge apache2\* 389\* cyrus-imapd\* postfix\* mysql-server\* roundcube\* pykolab\* kolab\* libkolab\* kolab-3\* php-net-ldap3

echo "deleting files..."
rm -Rf \
    /etc/postfix \
    /etc/apache2 \
    /etc/roundcubemail \
    /etc/kolab* \
    /etc/cyrus.conf \
    /etc/imapd.conf \
    /etc/dirsrv \
    /etc/ssl/private/example* \
    /etc/ssl/certs/example* \
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
  export obs=http://obs.kolabsys.com/repositories/
fi

cat > /etc/apt/sources.list.d/kolab.list <<FINISH
deb $obs/Kolab:/16/$OBS_repo_OS/ ./
FINISH

wget https://ssl.kolabsys.com/community.asc -O Release.key
apt-key add Release.key; rm -rf Release.key

cat > /etc/apt/preferences.d/kolab <<FINISH
Package: *
Pin: origin obs.kolabsys.com
Pin-Priority: 501
FINISH

apt-get -y install apt-transport-https
apt-get update
apt-get -y install aptitude

if [[ $OBS_repo_OS == "Debian_8.0" ]]
then
  # we do not want apache2 2.2 from KolabSys OBS
  apt-get -y install -t stable apache2 || exit 1
fi

aptitude -y install kolab kolab-freebusy || exit 1

