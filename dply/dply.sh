#!/bin/bash

swapsize="1GB"
branch="KolabWinterfell"
# recommended: use another password than test for user: cn=Directory Manager
pwd="test"

# add swap space to deal with small amount of RAM
fallocate -l $swapsize /swapfile1;
mkswap /swapfile1
swapon /swapfile1
echo "/swapfile1              swap                    swap    defaults        0 0" >> /etc/fstab

yum install -y wget
cd /root
wget https://raw.githubusercontent.com/TBits/KolabScripts/$branch/dply/reinstallKolab.sh -O dply$branch.sh
chmod a+x dply$branch.sh
sed -i 's#branch="KolabWinterfell"#branch="$branch"#g' dply$branch.sh

# you can rerun this script if you want to reinstall Kolab.
./dply$branch.sh $pwd

# next steps:
# http://your.ip/kolab-webadmin, login with user: cn=Directory Manager, password: as defined at the top of this script, default: test
# http://your.ip/roundcubemail
