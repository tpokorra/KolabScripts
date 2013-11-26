#!/bin/bash
# this script will remove Kolab, and DELETE all YOUR data!!!
# it will reinstall Kolab, from Kolab 3.1 Updates
# you can optionally install the patches from TBits, see bottom of script

if [ -f /etc/centos-release ]
then
  ./reinstallCentOS.sh CentOS_6
else
  if [ -f /etc/lsb-release ]
  then
    . /etc/lsb-release
    if [ $DISTRIB_ID == "Ubuntu" -a $DISTRIB_CODENAME="precise" ]
    then
      ./reinstallDebianUbuntu.sh Ubuntu_12.04
    fi
  else
    if [ -f /etc/debian_version ]
    then
      ./reinstallDebianUbuntu.sh Debian_7.0
    fi
  fi 
fi

echo "for the TBits patches for multi domain setup, please run "
echo "   ./initSetupKolabPatches.sh"
echo "   setup-kolab"
echo "    or unattended: setup-kolab --yes --quiet --timezone=Europe/Berlin"
echo '    echo "Password for cn=Directory Manager is: " `cat /etc/kolab/kolab.conf | grep "^bind_pw" | cut -d " " -f 3`'
echo "   ./initRoundcubePlugins.sh"
echo "   ./initMultiDomain.sh"
echo "   ./initMailForward.sh"
echo "   ./initTBitsISP.sh"
