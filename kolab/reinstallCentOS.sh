#!/bin/bash
# this script will remove Kolab, and DELETE all YOUR data!!!
# it will reinstall Kolab Winterfell
# you can optionally install the patches from TBits.net, see bottom of script reinstall.sh

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

systemctl stop kolabd
systemctl stop kolab-saslauthd
systemctl stop cyrus-imapd
systemctl stop dirsrv.target
systemctl stop wallace
systemctl stop clamd@amavisd
systemctl stop amavisd
systemctl stop httpd
systemctl stop mariadb

yum -y remove 389\* cyrus-imapd\* postfix\* mariadb-server\* guam\* roundcube\* pykolab\* kolab\* libkolab\* libcalendaring\* kolab-3\* httpd php-Net-LDAP3 up-imapproxy nginx stunnel

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

if [[ $OBS_repo_OS == CentOS* ]]
then
  yum -y install epel-release yum-utils
elif [[ $OBS_repo_OS == Fedora* ]]
then
  dnf -y install 'dnf-command(config-manager)'
fi

# could use environment variable obs=http://my.proxy.org/obs.kolabsys.com 
# see http://kolab.org/blog/timotheus-pokorra/2013/11/26/downloading-obs-repo-php-proxy-file
if [[ "$obs" = "" ]]
then
  export obs=http://obs.kolabsys.com/repositories/
fi

rm -f /etc/yum.repos.d/Kolab*.repo /etc/yum.repos.d/lbs-tbits.net-kolab-nightly.repo
if [[ $OBS_repo_OS == CentOS* ]]
then
  yum-config-manager --add-repo $obs/Kolab:/Winterfell/$OBS_repo_OS/Kolab:Winterfell.repo
elif [[ $OBS_repo_OS == Fedora* ]]
then
  dnf config-manager --add-repo $obs/Kolab:/Winterfell/$OBS_repo_OS/Kolab:Winterfell.repo
fi

rpm --import "https://ssl.kolabsys.com/community.asc"

# add priority = 1 to kolab repo files
for f in /etc/yum.repos.d/Kolab*.repo
do
    sed -i "s#enabled=1#enabled=1\npriority=1#g" $f
    sed -i "s#http://obs.kolabsys.com:82/#$obs/#g" $f
done

if [[ $OBS_repo_OS == CentOS* ]]
then
  yum clean metadata

  tryagain=0
  yum -y install kolab kolab-freebusy patch unzip || tryagain=1
  if [ $tryagain -eq 1 ]; then
    yum clean metadata
    yum -y install kolab kolab-freebusy patch unzip || exit -1
  fi
  yum -y install clamav-update || exit -1
elif [[ $OBS_repo_OS == Fedora* ]]
then
  dnf clean metadata
  dnf -y install kolab kolab-freebusy patch unzip || exit -1
  dnf -y install clamav-update || exit -1
fi

sed -i "s/^Example/#Example/g" /etc/freshclam.conf
sed -i "s/#DatabaseMirror db.XY.clamav.net/DatabaseMirror db.de.clamav.net/g" /etc/freshclam.conf
freshclam
