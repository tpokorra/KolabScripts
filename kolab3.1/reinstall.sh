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

echo "for the TBits patches for multi domain and ISP setup, please run "
echo "   ./initSetupKolabPatches.sh"
echo "   setup-kolab"
if [ -f /etc/sysconfig/clock ]
then
  # CentOS
  . /etc/sysconfig/clock
fi
if [ -f /etc/timezone ]
then
    # Debian
    ZONE=`cat /etc/timezone`
fi
echo "    or unattended: setup-kolab --default --timezone=$ZONE --directory-manager-pwd=test"
echo "   ./initSSL.sh"
echo "   ./initRoundcubePlugins.sh"
echo "   ./initMultiDomain.sh"
echo "   ./initMailForward.sh"
echo "   ./initMailCatchall.sh"
echo "   ./initTBitsISP.sh"
echo ""
echo "  also have a look at initTBitsCustomizationsDE.sh, perhaps there are some useful customizations for you as well"
