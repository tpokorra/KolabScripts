#!/bin/bash

#####################################################################################
#Removing Canonification from Cyrus IMAP
# TODO: could preserve canonification: http://www.intevation.de/pipermail/kolab-users/2012-August/013747.html
#####################################################################################
sed -r -i -e 's/^auth_mech/#auth_mech/g' /etc/imapd.conf
sed -r -i -e 's/^pts_module/#pts_module/g' /etc/imapd.conf
sed -r -i -e 's/^ldap_/#ldap_/g' /etc/imapd.conf
service cyrus-imapd restart

#####################################################################################
#Update Postfix LDAP Lookup Tables
# support subdomains too, search_base = dc=%3,dc=%2,dc=%1
# see http://www.intevation.de/pipermail/kolab-users/2013-January/014270.html
#####################################################################################
rm -f /etc/postfix/ldap/*_3.cf
for f in `find /etc/postfix/ldap/ -type f -name "*.cf" ! -name "mydestination.cf"`;
do
  f3=${f/.cf/_3.cf}
  cp $f $f3
  sed -r -i -e 's/^search_base = .*$/search_base = dc=%2,dc=%1/g' $f
  sed -r -i -e 's/^search_base = .*$/search_base = dc=%3,dc=%2,dc=%1/g' $f3
done
 
sed -r -i -e 's#^transport_maps = .*$#transport_maps = ldap:/etc/postfix/ldap/transport_maps.cf, ldap:/etc/postfix/ldap/transport_maps_3.cf#g' /etc/postfix/main.cf
sed -r -i -e 's#^virtual_alias_maps = .*$#virtual_alias_maps = $alias_maps, ldap:/etc/postfix/ldap/virtual_alias_maps.cf, ldap:/etc/postfix/ldap/mailenabled_distgroups.cf, ldap:/etc/postfix/ldap/mailenabled_dynamic_distgroups.cf, ldap:/etc/postfix/ldap/virtual_alias_maps_3.cf, ldap:/etc/postfix/ldap/mailenabled_distgroups_3.cf, ldap:/etc/postfix/ldap/mailenabled_dynamic_distgroups_3.cf#g' /etc/postfix/main.cf
sed -r -i -e 's#^local_recipient_maps = .*$#local_recipient_maps = ldap:/etc/postfix/ldap/local_recipient_maps.cf, ldap:/etc/postfix/ldap/local_recipient_maps_3.cf#g' /etc/postfix/main.cf
 
service postfix restart
 
#####################################################################################
#kolab_auth conf roundcube; see https://git.kolab.org/roundcubemail-plugins-kolab/commit/?id=1778b5ec70156f064fdda61c817c678001406996
#####################################################################################
sed -r -i -e "s#=> 389,#=> 389,\n        'domain_base_dn'            => 'cn=kolab,cn=config',\n        'domain_filter'             => '(\&(objectclass=domainrelatedobject)(associateddomain=%s))',\n        'domain_name_attr'          => 'associateddomain',#g" /etc/roundcubemail/kolab_auth.inc.php
sed -r -i -e "s#'ou=People,.*'#'ou=People,%dc'#g" /etc/roundcubemail/kolab_auth.inc.php
sed -r -i -e "s#'ou=Groups,.*'#'ou=Groups,%dc'#g" /etc/roundcubemail/kolab_auth.inc.php
 
#####################################################################################
#fix a problem with kolab lm, see http://www.intevation.de/pipermail/kolab-devel/2013-June/014492.html
#####################################################################################
sed -r -i -e "s/kolab_user_filter = /#kolab_user_filter = /g" /etc/kolab/kolab.conf

#####################################################################################
# apply a couple of patches, see related kolab bugzilla number in filename, eg. https://issues.kolab.org/show_bug.cgi?id=2018
#####################################################################################
patch -p1 -i `pwd`/patches/patchMultiDomainAdminsBug2018.patch -d /usr/share/kolab-webadmin
patch -p1 -i `pwd`/patches/mailquotaImprovedBug1966.patch -d /usr/share/kolab-webadmin
patch -p1 -i `pwd`/patches/validationOptionalValuesBug2045.patch -d /usr/share/kolab-webadmin
patch -p1 -i `pwd`/patches/domainquotaBug2046.patch -d /usr/share/kolab-webadmin

