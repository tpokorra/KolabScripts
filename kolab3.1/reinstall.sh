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
echo "   setup-kolab"
echo "   ./initRoundcubePlugins.sh"
echo "   ./initMultiDomain.sh"
echo "   ./initMailForward.sh"
echo "   ./initTBitsISP.sh"
