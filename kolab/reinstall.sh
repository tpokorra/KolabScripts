#!/bin/bash
# this script will remove Kolab, and DELETE all YOUR data!!!
# it will reinstall Kolab, from Kolab 3.3 Updates
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

if [ $? -ne 0 ]
then
  exit 1
fi

echo "for the TBits patches for multi domain and ISP setup, please run "
echo "   ./initSetupKolabPatches.sh"
echo "   setup-kolab"
ZONE="Europe/Brussels"
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
echo "    or unattended: echo 2 | setup-kolab --default --timezone=$ZONE --directory-manager-pwd=test"
h=`hostname`
echo "   ./initSSL.sh "${h:`expr index $h .`}
echo "   ./initRoundcubePlugins.sh"
echo "   ./initMultiDomain.sh"
echo "   ./initMailForward.sh"
echo "   ./initMailCatchall.sh"
echo "   ./initTBitsISP.sh"
echo ""
echo "  also have a look at initTBitsCustomizationsDE.sh, perhaps there are some useful customizations for you as well"
echo "  for running the pySeleniumTests, run initSleepTimesForTest.sh to increase the speed of domain and email account creation"
