#!/bin/bash

proxy=up-imapproxy
#proxy=nginx

if [[ "$proxy" = "up-imapproxy" ]]
then
  yum install -y up-imapproxy
  cp imapproxy/imapproxy.conf /etc/
  service imapproxy start
  chkconfig imapproxy on
fi

if [[ "$proxy" = "nginx" ]]
then
  yum install -y stunnel nginx
  cp imapproxy/stunnel.conf /etc/stunnel/stunnel.conf
  cp imapproxy/stunnel /etc/init.d/stunnel
  chmod a+x /etc/init.d/stunnel
  service stunnel start
  chkconfig stunnel on

  cp imapproxy/nginx.conf /etc/nginx/nginx.conf  
  service nginx start
  chkconfig nginx on
fi

# change configuration of roundcube, now use the imap proxy
sed -i "s/config\['default_port'\] = 143/config['default_port'] = 8143/g" /etc/roundcubemail/config.inc.php

