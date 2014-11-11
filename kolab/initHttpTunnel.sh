#!/bin/bash

#####################################################################################
# make sure that kolab webadmin works even on my virtual machine with routed port 80
#####################################################################################
sed -r -i \
    -e '/api_url/d' \
    -e "s#\[kolab_wap\]#[kolab_wap]\napi_url = http://localhost/kolab-webadmin/api#g" \
    /etc/kolab/kolab.conf

sed -i -e "s#?>#    \$config['file_api_url'] = 'http://localhost/chwala/api/';\n\n?>#g" /etc/roundcubemail/config.inc.php

patch -p1 -i `pwd`/patches/roundcube_behind_tunnel.patch -d /usr/share/roundcubemail
patch -p1 -i `pwd`/patches/roundcube_kolab_files_url_localhostBug3573.patch -d /usr/share/roundcubemail
