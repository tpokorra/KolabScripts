#!/bin/bash

#####################################################################################
# enable mail forwarding only users
#####################################################################################

cp /etc/postfix/ldap/virtual_alias_maps.cf /etc/postfix/ldap/virtual_alias_maps_forward.cf
sed -i -e 's#^query_filter = .*#query_filter = (\&(|(mail=%s)(alias=%s))(objectclass=inetorgperson))#g' /etc/postfix/ldap/virtual_alias_maps_forward.cf
sed -i -e 's#^result_attribute = .*#result_attribute = mailForwardingAddress#g' /etc/postfix/ldap/virtual_alias_maps_forward.cf

cp /etc/postfix/ldap/virtual_alias_maps_3.cf /etc/postfix/ldap/virtual_alias_maps_forward_3.cf
sed -i -e 's#^query_filter = .*#query_filter = (\&(|(mail=%s)(alias=%s))(objectclass=inetorgperson))#g' /etc/postfix/ldap/virtual_alias_maps_forward_3.cf
sed -i -e 's#^result_attribute = .*#result_attribute = mailForwardingAddress#g' /etc/postfix/ldap/virtual_alias_maps_forward_3.cf

sed -i -e 's#ldap:/etc/postfix/ldap/virtual_alias_maps.cf#ldap:/etc/postfix/ldap/virtual_alias_maps.cf, ldap:/etc/postfix/ldap/virtual_alias_maps_forward.cf#' /etc/postfix/main.cf
sed -i -e 's#ldap:/etc/postfix/ldap/virtual_alias_maps_3.cf#ldap:/etc/postfix/ldap/virtual_alias_maps_3.cf, ldap:/etc/postfix/ldap/virtual_alias_maps_forward_3.cf#' /etc/postfix/main.cf

service postfix restart

#####################################################################################
#disable LDAP debugging
#####################################################################################
sed -r -i -e 's/config_set\("debug", true\)/config_set("debug", false)/g' /usr/share/kolab-webadmin/lib/Auth/LDAP.php

