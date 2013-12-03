#!/bin/bash

#####################################################################################
# enable catchall mail addresses
#####################################################################################

filename=/etc/postfix/ldap/virtual_alias_maps_catchall.cf
filename_3=/etc/postfix/ldap/virtual_alias_maps_catchall_3.cf
cp /etc/postfix/ldap/virtual_alias_maps.cf $filename
sed -i -e 's#^query_filter = .*#query_filter = (\&(alias=@%d)(objectclass=inetorgperson))#g' $filename

cp /etc/postfix/ldap/virtual_alias_maps_3.cf $filename_3
sed -i -e 's#^query_filter = .*#query_filter = (\&(alias=@%d)(objectclass=inetorgperson))#g' $filename_3

sed -i -e "s#ldap:/etc/postfix/ldap/virtual_alias_maps.cf#ldap:/etc/postfix/ldap/virtual_alias_maps.cf, ldap:$filename#" /etc/postfix/main.cf
sed -i -e "s#ldap:/etc/postfix/ldap/virtual_alias_maps_3.cf#ldap:/etc/postfix/ldap/virtual_alias_maps_3.cf, ldap:$filename_3#" /etc/postfix/main.cf

postmap $filename
postmap $filename_3
service postfix restart

#####################################################################################
# apply a couple of patches, see related kolab bugzilla number in filename, eg. https://issues.kolab.org/show_bug.cgi?id=1869
#####################################################################################

patch -p1 -i `pwd`/patches/allowCatchallAliasBug2648.patch -d /usr/share/kolab-webadmin
