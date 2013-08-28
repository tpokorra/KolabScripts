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
#kolab_auth conf roundcube; see https://git.kolab.org/roundcubemail-plugins-kolab/commit/?id=1778b5ec70156f064fdda61c817c678001406996
#####################################################################################
sed -r -i -e "s#=> 389,#=> 389,\n        'domain_base_dn'            => 'cn=kolab,cn=config',\n        'domain_filter'             => '(\&(objectclass=domainrelatedobject)(associateddomain=%s))',\n        'domain_name_attr'          => 'associateddomain',#g" /etc/roundcubemail/kolab_auth.inc.php
sed -r -i -e "s#'ou=People,.*'#'ou=People,%dc'#g" /etc/roundcubemail/kolab_auth.inc.php
sed -r -i -e "s#'ou=Groups,.*'#'ou=Groups,%dc'#g" /etc/roundcubemail/kolab_auth.inc.php
 
#####################################################################################
#fix a problem with kolab lm, see http://lists.kolab.org/pipermail/devel/2013-June/014435.html
#####################################################################################
sed -r -i -e "s/kolab_user_filter = /#kolab_user_filter = /g" /etc/kolab/kolab.conf

#####################################################################################
#set primary_mail value in ldap section, so that new users in a different domain will have a proper primary email address, even without changing kolab.conf for each domain
#####################################################################################
sed -r -i -e "s/\[ldap\]/[ldap]\nprimary_mail = %(givenname)s.%(surname)s@%(domain)s/g" /etc/kolab/kolab.conf

#####################################################################################
# install our modified version of the message_label plugin to support virtual folders aka imap flags
# see  https://github.com/tpokorra/message_label/tree/message_label_tbits
#####################################################################################
wget https://github.com/tpokorra/message_label/archive/message_label_tbits.zip -O message_label.zip
yum -y install unzip
unzip message_label.zip
rm -f message_label.zip
mv message_label-message_label_tbits /usr/share/roundcubemail/plugins/message_label
sed -r -i -e "s#'redundant_attachments',#'redundant_attachments',\n            'message_label',#g" /etc/roundcubemail/config.inc.php
# probably a dirty hack: we need to force fetching the headers, so that the labels are always displayed
sed -i -e 's#function fetch_headers($folder, $msgs, $sort = true, $force = false)#function fetch_headers($folder, $msgs, $sort = true, $forcedummy = false, $force = true)#g' /usr/share/roundcubemail/program/lib/Roundcube/rcube_imap.php

#####################################################################################
# apply a patch to roundcube plugin managesieve, to support the labels set with message_label plugin.
# see https://github.com/tpokorra/roundcubemail/commits/manage_sieve_using_message_label_flags
#####################################################################################
patch -p1 -i `pwd`/patches/managesieveWithMessagelabel.patch -d /usr/share/roundcubemail

#####################################################################################
# apply a couple of patches, see related kolab bugzilla number in filename, eg. https://issues.kolab.org/show_bug.cgi?id=2018
#####################################################################################
patch -p1 -i `pwd`/patches/patchMultiDomainAdminsBug2018.patch -d /usr/share/kolab-webadmin
patch -p1 -i `pwd`/patches/validationOptionalValuesBug2045.patch -d /usr/share/kolab-webadmin
patch -p1 -i `pwd`/patches/domainquotaBug2046.patch -d /usr/share/kolab-webadmin
patch -p1 -i `pwd`/patches/primaryMailBug1925.patch -d /usr/share/kolab-webadmin
patch -p1 -i `pwd`/patches/deleteDomainWithUsersBug1869.patch -d /usr/share/kolab-webadmin

