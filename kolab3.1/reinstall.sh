# this script will remove Kolab, and DELETE all YOUR data!!!
# it will reinstall Kolab, from the nightly build from Kolab git trunk
# you can optionally install the patches from TBits, see bottom of script

service kolabd stop
service kolab-saslauthd stop
service cyrus-imapd stop
service dirsrv stop
service wallace stop
service httpd stop

yum -y remove 389\* cyrus-imapd\* postfix\* mysql-server\* roundcube\* pykolab\* kolab\* libkolab\* kolab-3\*

echo "deleting files..."
rm -Rf \
    /etc/dirsrv \
    /etc/kolab/kolab.conf \
    /etc/postfix \
    /usr/lib64/dirsrv \
    /usr/share/kolab-webadmin \
    /usr/share/roundcubemail \
    /usr/share/kolab-syncroton \
    /usr/share/kolab \
    /usr/share/dirsrv \
    /var/cache/dirsrv \
    /var/log/kolab* \
    /var/log/dirsrv \
    /var/log/roundcube \
    /var/log/maillog \
    /var/lib/dirsrv \
    /var/lib/imap \
    /var/lib/kolab \
    /var/lib/mysql \
    /var/spool/imap \
    /var/spool/postfix

/etc/init.d/rsyslog restart

rm -f kolab-3*.rpm
rm -f epel*rpm
wget http://ftp.uni-kl.de/pub/linux/fedora-epel/6/i386/epel-release-6-8.noarch.rpm
yum -y localinstall --nogpgcheck epel-release-6-8.noarch.rpm
wget http://mirror.kolabsys.com/pub/redhat/kolab-3.1/el6/development/x86_64/kolab-3.1-community-release-6-2.el6.kolab_3.1.noarch.rpm
wget http://mirror.kolabsys.com/pub/redhat/kolab-3.1/el6/development/x86_64/kolab-3.1-community-release-development-6-2.el6.kolab_3.1.noarch.rpm
yum -y localinstall kolab-3*.rpm
rm -f kolab-3*.rpm
rm -f epel*rpm

rm -Rf /etc/yum.repos.d/bintray-tpokorra-kolab.repo
wget https://bintray.com/tpokorra/kolab/rpm -O /etc/yum.repos.d/bintray-tpokorra-kolab.repo --no-check-certificate

yum clean metadata
yum install kolab

patch -p0 -i patches/nsRoleDNBug1510.patch
setup-kolab

if [ "1" -eq "2" ]
then
    patch -p1 -i `pwd`/patches/patchMultiDomainAdminsBug2018.patch -d /usr/share/kolab-webadmin
    patch -p1 -i `pwd`/patches/mailquotaImprovedBug1966.patch -d /usr/share/kolab-webadmin
    patch -p1 -i `pwd`/patches/validationOptionalValuesBug2045.patch -d /usr/share/kolab-webadmin
    patch -p1 -i `pwd`/patches/domainquotaBug2046.patch -d /usr/share/kolab-webadmin
    ./initMultiDomain.sh
fi
