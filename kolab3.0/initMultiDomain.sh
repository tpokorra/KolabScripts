#!/bin/bash

if [ -z "$1" ]
then
   echo "call $0 <ldap password for cn=Directory Manager>"
   exit 1
fi
 
DirectoryManagerPwd=$1

#####################################################################################
#Removing Canonification from Cyrus IMAP
# TODO: could preserve canonification: http://lists.kolab.org/pipermail/users/2012-August/013711.html
#####################################################################################
sed -r -i -e 's/^auth_mech/#auth_mech/g' /etc/imapd.conf
sed -r -i -e 's/^pts_module/#pts_module/g' /etc/imapd.conf
sed -r -i -e 's/^ldap_/#ldap_/g' /etc/imapd.conf
service cyrus-imapd restart

#####################################################################################
#Update Postfix LDAP Lookup Tables
# support subdomains too, search_base = dc=%3,dc=%2,dc=%1
# see https://lists.kolab.org/pipermail/users/2013-January/014233.html
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
# withdraw permissions for all users from the default domain, which is used to manage the domain admins
#####################################################################################
management_domain=`cat /etc/kolab/kolab.conf | grep primary_domain`
management_domain=${management_domain:17}
cat > ./ldapparam.txt <<END
dn: associateddomain=$management_domain,cn=kolab,cn=config
changetype: modify
delete: aci
END
ldapmodify -x -h localhost -D "cn=Directory Manager" -w $DirectoryManagerPwd -f ./ldapparam.txt
rm -f ldapparam.txt

#####################################################################################
# install our modified version of the message_label plugin to support virtual folders aka imap flags
# see  https://github.com/tpokorra/message_label/tree/message_label_tbits
#####################################################################################
wget https://github.com/tpokorra/message_label/archive/message_label_tbits.zip -O message_label.zip
unzip message_label.zip
rm message_label.zip
mv message_label-message_label_tbits /usr/share/roundcubemail/plugins/message_label
sed -r -i -e "s#'redundant_attachments',#'redundant_attachments',\n            'message_label',#g" /etc/roundcubemail/main.inc.php
# probably a dirty hack: we need to force fetching the headers, so that the labels are always displayed
sed -i -e 's#function fetch_headers($folder, $msgs, $sort = true, $force = false)#function fetch_headers($folder, $msgs, $sort = true, $forcedummy = false, $force = true)#g' /usr/share/roundcubemail/program/lib/Roundcube/rcube_imap.php

#####################################################################################
# apply a patch to roundcube plugin managesieve, to support the labels set with message_label plugin.
# see https://github.com/tpokorra/roundcubemail/commits/manage_sieve_using_message_label_flags
#####################################################################################
patch -p3 -i `pwd`/patches/managesieveWithMessagelabel.patch -d /usr/share/roundcubemail

#####################################################################################
# Make sure that in a multi-domain environment, we get the base dn for additional domain name spaces right.
# see https://git.kolab.org/pykolab/commit/?id=c915487867d227617f8ae7d996af51e5470ff54e
#####################################################################################
patch -p0 -i patches/pykolab2013-05-23.patch

#####################################################################################
# kolab list-mailbox-metadata does not work for folders with space in name
# patch for cyruslib: see https://git.kolab.org/pykolab/commit/?id=f9c50355bd0be03b80d952325b4fa4d740ad4c19
#####################################################################################
patch -p0 -i patches/cyruslib2013-05-22.patch

#####################################################################################
# apply a couple of patches, see related kolab bugzilla number in filename, eg. https://issues.kolab.org/show_bug.cgi?id=2018
##################################################################################### 
patch -p1 -d /usr/share/kolab-webadmin < patches/patchMultiDomainAdminsBug2018.patch
patch -p1 -d /usr/share/kolab-webadmin < patches/mailquotaBug1966.patch
patch -p1 -d /usr/share/kolab-webadmin < patches/validationOptionalValuesBug2045.patch
patch -p1 -d /usr/share/kolab-webadmin < patches/domainquotaBug2046.patch
patch -p1 -d /usr/share/kolab-webadmin < patches/primaryMailBug1925.patch
patch -p1 -d /usr/share/kolab-webadmin < patches/deleteDomainWithUsersBug1869.patch
patch -p0 -i patches/domainSelectorBug2005.patch
patch /usr/share/roundcubemail/plugins/kolab_auth/kolab_auth.php patches/roundcubeKolabAuthBug1926.patch
patch /usr/share/kolab-syncroton/lib/plugins/kolab_auth/kolab_auth.php patches/syncrotonKolabAuthBug1926.patch
