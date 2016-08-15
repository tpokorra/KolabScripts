#!/bin/bash

#####################################################################################
# enable catchall mail addresses
#####################################################################################

filename=/etc/postfix/ldap/virtual_alias_maps_catchall.cf
filename_3=/etc/postfix/ldap/virtual_alias_maps_catchall_3.cf
cp /etc/postfix/ldap/virtual_alias_maps.cf $filename
sed -i -e 's#^query_filter = .*#query_filter = (\&(alias=catchall@%d)(objectclass=inetorgperson))#g' $filename

cp /etc/postfix/ldap/virtual_alias_maps_3.cf $filename_3
sed -i -e 's#^query_filter = .*#query_filter = (\&(alias=catchall@%d)(objectclass=inetorgperson))#g' $filename_3

sed -i -e "s#^virtual_alias_maps = \(.*\)#virtual_alias_maps = \1, ldap:$filename, ldap:$filename_3#" /etc/postfix/main.cf

postmap $filename
postmap $filename_3
service postfix restart
