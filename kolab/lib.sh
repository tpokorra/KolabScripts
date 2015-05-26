#!/bin/bash

patchesurl=https://raw.github.com/TBits/KolabScripts/master/kolab/patches

function DetermineOS
{
  export OS=
  if [ -f /etc/centos-release ]
  then
    release=`cat /etc/centos-release`
    if [[ $release == CentOS\ Linux\ release\ 6* ]]
    then
      export OS=CentOS_6
    elif [[ $release == CentOS\ Linux\ release\ 7* ]]
      export OS=CentOS_7
    fi
  elif [ -f /etc/redhat-release ]
  then
    release=`cat /etc/redhat-release`
    if [[ $release == Fedora\ release\ 20\ * ]]
    then
      export OS=Fedora_20
    elif [[ $release == Fedora\ release\ 21\ * ]]
    then
      export OS=Fedora_21
    elif [[ $release == Fedora\ release\ 22\ * ]]
    then
      export OS=Fedora_22
    fi
  elif [ -f /etc/lsb-release ]
  then
    . /etc/lsb-release
    if [ $DISTRIB_ID == "Ubuntu" -a $DISTRIB_CODENAME == "precise" ]
    then
      export OS=Ubuntu_12.04
    elif [ $DISTRIB_ID == "Ubuntu" -a $DISTRIB_CODENAME == "trusty" ]
    then
      export OS=Ubuntu_14.04
    fi
  elif [ -f /etc/debian_version ]
  then
    release=`cat /etc/debian_version`
    if [[ $release == 7* ]]
    then
      export OS=Debian_7.0
    elif [[ $release == 8* ]]
      export OS=Debian_8.0
    fi
  fi
}

function InstallWgetAndPatch()
{
  if [ $OS == CentOS* -o $OS == Fedora* ]
  then
    if [[ ! `which wget` || ! `which patch` ]]; then
      yum -y install wget patch
    fi
  elif [ $OS == Ubuntu* -o $OS == Debian* ]
    if [[ ! `which wget` || ! `which patch` ]]; then
      apt-get -y install wget patch;
    fi
  fi
}

# different paths in debian and centOS
DeterminePythonPath()
{
  export pythonDistPackages=/usr/lib/python2.7/dist-packages
  # Debian
  if [ ! -d $pythonDistPackages ]; then
    # centOS
    export pythonDistPackages=/usr/lib/python2.6/site-packages
    if [ ! -d $pythonDistPackages ]; then
      # centOS7
      export pythonDistPackages=/usr/lib/python2.7/site-packages
    fi
  fi
}

# function to start/stop/restart the Kolab Service, define action as first parameter!
function KolabService()
  action=$1
  if [ -f /bin/systemctl -a -f /etc/debian_version ]
  then
    /bin/systemctl $action kolab-server
  elif [ -f /bin/systemctl ]
  then
    /bin/systemctl $action kolabd.service
  elif [ -f /sbin/service ]
  then
    service kolabd $action
  elif [ -f /usr/sbin/service ]
  then
    service kolab-server $action
  fi
}
