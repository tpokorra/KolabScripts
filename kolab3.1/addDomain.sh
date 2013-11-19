#!/bin/bash

if [ -z "$1" ]
then
   echo "call $0 <domain>"
   exit 1
fi

DOM=$1
DC=$(echo -n $DOM | sed 's/\./,dc=/g' | sed 's/^/dc=/')

echo "[$DOM]
base_dn = $DC
primary_mail = %(givenname)s.%(surname)s@%(domain)s
" >> /etc/kolab/kolab.conf

# different service-names on centOs (httpd) and debian (apache2)
if which /etc/init.d/apache2; then 
  /etc/init.d/apache2 reload; 
else
  service httpd reload;
fi
