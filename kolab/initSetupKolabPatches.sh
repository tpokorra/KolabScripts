#!/bin/bash

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

DetermineOS
InstallWgetAndPatch
DeterminePythonPath

#####################################################################################
# apply a couple of patches, see related kolab bugzilla number in filename, eg. https://issues.kolab.org/show_bug.cgi?id=2018
#####################################################################################

if [ -z $APPLYPATCHES ]
then
  APPLYPATCHES=1
fi

if [ $APPLYPATCHES -eq 1 ]
then
echo "applying patch for Roundcube Kolab plugin for storage in MariaDB"
patch -p1 -i `pwd`/patches/roundcubeStorageMariadbBug4883.patch -d /usr/share/roundcubemail || exit -1

# TODO: see if we still need these patches
#echo "applying patch for waiting after restart of dirsrv (necessary on Debian)"
#patch -p1 -i `pwd`/patches/setupKolabSleepDirSrv.patch -d $pythonDistPackages || exit -1

# https://github.com/TBits/KolabScripts/issues/76
echo "fix problem on LXC containers with access to TCP keepalive settings"
patch -p1 -i `pwd`/patches/fixPykolabIMAPKeepAlive.patch -d $pythonDistPackages || exit -1

echo "applying patch to Roundcube for the compose to show loading message"
# patch -p1 -i `pwd`/patches/roundcubeComposeLoading.patch -d /usr/share/roundcubemail || exit -1
# app.js has been compressed
sed -i "s#this.open_compose_step=function(p){var url#this.open_compose_step=function(p){this.set_busy(true, 'loading');var url#g" /usr/share/roundcubemail/public_html/assets/program/js/app.js
fi

if [[ $OS == Debian* ]]
then
      # workaround for bug 2050, https://issues.kolab.org/show_bug.cgi?id=2050
      echo "export ZEND_DONT_UNLOAD_MODULES=1" >> /etc/apache2/envvars

      # TODO on Debian, we need to install the rewrite for the csrf token
      newConfigLines="\tRewriteEngine On\n \
\tRewriteRule ^/roundcubemail/[a-f0-9]{16}/(.*) /roundcubemail/\$1 [PT,L]\n \
\tRewriteRule ^/webmail/[a-f0-9]{16}/(.*) /webmail/\$1 [PT,L]\n \
\tRedirectMatch ^/$ /roundcubemail/\n"

#      sed -i -e "s~</VirtualHost>~$newConfigLines</VirtualHost>~" /etc/apache2/sites-enabled/000-default
fi
