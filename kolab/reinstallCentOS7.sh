#!/bin/bash
# this script will remove Kolab, and DELETE all YOUR data!!!
# it will reinstall Kolab, from Kolab 3.4 Updates
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
if [[ "$OBS_repo_OS" == "CentOS_7" ]]
then
  COPR_repo_OS="epel-7"
elif [["$OBS_repo_OS" == "Fedora_23" ]]
then
  COPR_repo_OS="fedora-23"
fi

systemctl stop kolabd
systemctl stop kolab-saslauthd
systemctl stop cyrus-imapd
systemctl stop dirsrv.target
systemctl stop wallace
systemctl stop httpd
systemctl stop mariadb

yum -y remove 389\* cyrus-imapd\* postfix\* mariadb-server\* roundcube\* pykolab\* kolab\* libkolab\* libcalendaring\* kolab-3\* httpd php-Net-LDAP3 up-imapproxy nginx stunnel

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

if [[ ! $OBS_repo_OS == Fedora* ]]
then
  yum -y install epel-release
fi

# could use environment variable copr=https://copr.fedoraproject.org/coprs/myuser
if [[ "$copr" = "" ]]
then
  export copr=https://copr.fedoraproject.org/coprs/tpokorra
fi

# could use environment variable obs=http://my.proxy.org/obs.kolabsys.com
# see http://kolab.org/blog/timotheus-pokorra/2013/11/26/downloading-obs-repo-php-proxy-file
if [[ "$obs" = "" ]]
then
  export obs=http://obs.kolabsys.com/repositories/
fi

cd /etc/yum.repos.d
rm -Rf kolab-*.repo
#wget $copr/Kolab-3.4/repo/${COPR_repo_OS}/tpokorra-Kolab-3.4-${COPR_repo_OS}.repo -O kolab-3.4.repo
#wget $copr/Kolab-3.4-Updates/repo/${COPR_repo_OS}/tpokorra-Kolab-3.4-Updates-${COPR_rep_OS}.repo -O kolab-3.4-updates.repo
wget $obs/Kolab:/3.4/$OBS_repo_OS/Kolab:3.4.repo -O kolab-3.4.repo
wget $obs/Kolab:/3.4:/Updates/$OBS_repo_OS/Kolab:3.4:Updates.repo -O kolab-3.4-updates.repo
cd -

yum -y install gnupg2
# manually: gpg --search devel@lists.kolab.org
gpg --import key/devel\@lists.kolab.org.asc
rpm --import key/devel\@lists.kolab.org.asc

# add priority = 0 to kolab repo files
for f in /etc/yum.repos.d/kolab-3*.repo
do
    sed -i "s#enabled=1#enabled=1\npriority=0#g" $f
done

# do not install roundcube packages from epel. we need the kolab packages
# epel has roundcubemail-1.1.3-1.el7.noarch
# kolab has roundcubemail-core-1.1.2-4.8.el7.kolab_3.4.noarch
if [ -f /etc/yum.repos.d/epel.repo ]
then
  sed -i "s#enabled=1#enabled=1\nexclude=roundcubemail*#g" /etc/yum.repos.d/epel.repo
fi

yum clean metadata
yum -y install kolab kolab-freebusy patch unzip

