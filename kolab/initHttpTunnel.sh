#!/bin/bash

#####################################################################################
# make sure that kolab webadmin works even on my virtual machine with routed port 80
#####################################################################################
sed -r -i \
    -e '/api_url/d' \
    -e "s#\[kolab_wap\]#[kolab_wap]\napi_url = http://localhost/kolab-webadmin/api#g" \
    /etc/kolab/kolab.conf

sed -i -e "s#?>#    \$config['kolab_files_server_url'] = 'http://localhost/chwala/';\n\n?>#g" /etc/roundcubemail/config.inc.php
