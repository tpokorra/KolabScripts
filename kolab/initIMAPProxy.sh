#!/bin/bash

proxy=up-imapproxy
#proxy=nginx

yum install -y stunnel $proxy

cp imapproxy/stunnel.conf /etc/stunnel/stunnel.conf
cp imapproxy/stunnel /etc/init.d/stunnel
chmod a+x /etc/init.d/stunnel
service stunnel start
service stunnel on

if [[ "$proxy" -eq "up-imapproxy" ]]
then
  cp imapproxy/imapproxy.conf /etc/
  service imapproxy start
  chkconfig imapproxy on
fi

if [[ "$proxy" -eq "nginx" ]]
then
  cp imapproxy/nginx.conf /etc/nginx/nginx.conf  
  service nginx start
  chkconfig nginx on
fi

# change configuration of roundcube, now use the imap proxy
sed -i "s/config\['default_port'\] = 143/config['default_port'] = 8143/g" /etc/roundcubemail/config.inc.php

