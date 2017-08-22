#!/bin/bash

#####################################################################################
# make sure that kolab webadmin works even on my virtual machine with routed port 80
#####################################################################################
sed -r -i \
    -e '/api_url/d' \
    -e "s#\[kolab_wap\]#[kolab_wap]\napi_url = http://localhost/kolab-webadmin/api#g" \
    /etc/kolab/kolab.conf

sed -i -e "s#?>#    \$config['file_api_url'] = 'http://localhost/chwala/api/';\n\n?>#g" /etc/roundcubemail/config.inc.php

if [ -z $APPLYPATCHES ] 
then
  APPLYPATCHES=1
fi

if [ $APPLYPATCHES -eq 1 ]
then
  # not applying this patch because it fails. things should have been fixed, see https://git.kolab.org/T2426
  #patch -p1 -i `pwd`/patches/roundcube_kolab_files_url_localhostBug3573.patch -d /usr/share/roundcubemail || exit -1
fi
