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

service httpd reload
