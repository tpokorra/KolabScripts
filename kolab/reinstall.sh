#!/bin/bash
# this script will remove Kolab, and DELETE all YOUR data!!!
# it will reinstall Kolab, from Kolab 3.4 Updates
# you can optionally install the patches from TBits, see bottom of script

if [ -f /etc/centos-release ]
then
  release=`cat /etc/centos-release`
  if [[ $release == CentOS\ Linux\ release\ 7* ]]
  then
    ./reinstallCentOS7.sh CentOS_7
  else
    ./reinstallCentOS.sh CentOS_6
  fi
elif [ -f /etc/redhat-release ]
then
  release=`cat /etc/redhat-release`
  if [[ $release == Fedora\ release\ 23\ * ]]
  then
    ./reinstallCentOS7.sh Fedora_23
  fi
elif [ -f /etc/lsb-release ]
then
  . /etc/lsb-release
  if [ $DISTRIB_ID == "Ubuntu" -a $DISTRIB_CODENAME == "precise" ]
  then
    ./reinstallDebianUbuntu.sh Ubuntu_12.04
  elif [ $DISTRIB_ID == "Ubuntu" -a $DISTRIB_CODENAME == "trusty" ]
  then
    ./reinstallDebianUbuntu.sh Ubuntu_14.04
  fi
elif [ -f /etc/debian_version ]
then
  release=`cat /etc/debian_version`
  if [[ $release == 8* ]]
  then
    ./reinstallDebianUbuntu.sh Debian_8.0
  else
    ./reinstallDebianUbuntu.sh Debian_7.0
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
echo "   ./initHttpTunnel.sh"
#echo "   ./initIMAPProxy.sh"
echo "   ./initSSL.sh "${h:`expr index $h .`}
#echo "   ./initRoundcubePlugins.sh"
echo "   ./initMultiDomain.sh"
echo "   ./initMailForward.sh"
echo "   ./initMailCatchall.sh"
echo "   ./initTBitsISP.sh"
echo ""
echo "  also have a look at initTBitsCustomizationsDE.sh, perhaps there are some useful customizations for you as well"
echo "  for running the pySeleniumTests, run initSleepTimesForTest.sh to increase the speed of domain and email account creation"
