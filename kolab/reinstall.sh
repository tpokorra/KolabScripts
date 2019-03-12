#!/bin/bash
# this script will remove Kolab, and DELETE all YOUR data!!!
# it will reinstall Kolab Winterfell
# you can optionally install the patches from TBits, see bottom of script

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

DetermineOS

if [[ $OS == CentOS_6 ]]
then
  echo "CentOS6 not supported since Kolab 3.5"
  exit 1
elif [[ $OS == CentOS_* ]]
then
  ./reinstallCentOS.sh $OS || exit 1
elif [[ $OS == Fedora_* ]]
then
  ./reinstallCentOS.sh $OS || exit 1
elif [[ $OS == Ubuntu_* ]]
then
  ./reinstallDebianUbuntu.sh $OS || exit 1
elif [[ $OS == Debian_* ]]
then
  ./reinstallDebianUbuntu.sh $OS || exit 1
else
  echo Your Operating System is currently not supported
  exit 1
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
echo "    or unattended: setup-kolab --default --mysqlserver=new --timezone=$ZONE --directory-manager-pwd=test"
h=`hostname`
echo "   #./disableGuam.sh   # recommended in Winterfell, until Guam is working properly. see T1305"
echo "   ./initHttpTunnel.sh"
#echo "   ./initIMAPProxy.sh"
echo "   ./initSSL.sh "${h:`expr index $h .`}
#echo "   ./initRoundcubePlugins.sh"
echo "   ./initMultiDomain.sh"
echo "   ./disableCanonification.sh # for unpatched and old Cyrus 2.5"
echo "   ./initMailForward.sh"
echo "   ./initMailCatchall.sh"
echo "   ./initTBitsISP.sh"
echo ""
echo "  also have a look at initTBitsCustomizationsDE.sh, perhaps there are some useful customizations for you as well"
echo "  for running the pySeleniumTests, run initSleepTimesForTest.sh to increase the speed of domain and email account creation"
