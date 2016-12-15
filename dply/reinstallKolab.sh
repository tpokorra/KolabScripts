#!/bin/bash

if [ -z "$1" ]; then
  pwd="test"
else
  pwd=$1
fi

if [ -z "$2" ]; then
  branch="KolabWinterfell"
else
  branch=$1
fi

# we need a fully qualified domain name
hostnamectl set-hostname $branch.demo.example.org

yum install -y wget which bzip2 mailx selinux-policy-targeted
# disable SELinux
sed -i 's/enforcing/permissive/g' /etc/selinux/config

wget -O $branch.tar.gz https://github.com/TBits/KolabScripts/archive/$branch.tar.gz
tar xzf $branch.tar.gz
cd KolabScripts-$branch/kolab
# to make Kolab run on 512 MB of RAM on dply.co, disable Amavis and ClamAV
export WITHOUTSPAMFILTER=1
echo "y" | ./reinstall.sh || exit 1
./initSetupKolabPatches.sh || exit 1

setup-kolab --default --mysqlserver=new --timezone=Europe/Berlin --directory-manager-pwd=$pwd || exit 1

# next steps:
# http://your.ip/kolab-webadmin, login with user: cn=Directory Manager, password: as passed to this script, default: test
# http://your.ip/roundcubemail
