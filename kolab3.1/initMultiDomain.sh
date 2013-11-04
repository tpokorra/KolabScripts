#!/bin/bash

#####################################################################################
#Removing Canonification from Cyrus IMAP
# TODO: could preserve canonification: http://lists.kolab.org/pipermail/users/2012-August/013711.html
#####################################################################################
cp -f /etc/imapd.conf /etc/imapd.conf.beforeMultiDomain
sed -r -i -e 's/^auth_mech/#auth_mech/g' /etc/imapd.conf
sed -r -i -e 's/^pts_module/#pts_module/g' /etc/imapd.conf
sed -r -i -e 's/^ldap_/#ldap_/g' /etc/imapd.conf
service cyrus-imapd restart

#####################################################################################
#Update Postfix LDAP Lookup Tables
# support subdomains too, search_base = dc=%3,dc=%2,dc=%1
# see https://lists.kolab.org/pipermail/users/2013-January/014233.html
#####################################################################################

cp -Rf /etc/postfix/ldap /etc/postfix/ldap.beforeMultiDomain
rm -f /etc/postfix/ldap/*_3.cf
for f in `find /etc/postfix/ldap/ -type f -name "*.cf" ! -name "mydestination.cf"`;
do
  f3=${f/.cf/_3.cf}
  cp $f $f3
  sed -r -i -e 's/^search_base = .*$/search_base = dc=%2,dc=%1/g' $f
  sed -r -i -e 's/^search_base = .*$/search_base = dc=%3,dc=%2,dc=%1/g' $f3
done

cp -f /etc/postfix/main.cf /etc/postfix/main.cf.beforeMultiDomain
sed -r -i -e 's#^transport_maps = .*$#transport_maps = ldap:/etc/postfix/ldap/transport_maps.cf, ldap:/etc/postfix/ldap/transport_maps_3.cf#g' /etc/postfix/main.cf
sed -r -i -e 's#^virtual_alias_maps = .*$#virtual_alias_maps = $alias_maps, ldap:/etc/postfix/ldap/virtual_alias_maps.cf, ldap:/etc/postfix/ldap/mailenabled_distgroups.cf, ldap:/etc/postfix/ldap/mailenabled_dynamic_distgroups.cf, ldap:/etc/postfix/ldap/virtual_alias_maps_3.cf, ldap:/etc/postfix/ldap/mailenabled_distgroups_3.cf, ldap:/etc/postfix/ldap/mailenabled_dynamic_distgroups_3.cf#g' /etc/postfix/main.cf
sed -r -i -e 's#^local_recipient_maps = .*$#local_recipient_maps = ldap:/etc/postfix/ldap/local_recipient_maps.cf, ldap:/etc/postfix/ldap/local_recipient_maps_3.cf#g' /etc/postfix/main.cf
 
service postfix restart

#####################################################################################
#kolab_auth conf roundcube; see https://git.kolab.org/roundcubemail-plugins-kolab/commit/?id=1778b5ec70156f064fdda61c817c678001406996
#####################################################################################
cp -r /etc/roundcubemail/kolab_auth.inc.php /etc/roundcubemail/kolab_auth.inc.php.beforeMultiDomain
sed -r -i -e "s#=> 389,#=> 389,\n        'domain_base_dn'            => 'cn=kolab,cn=config',\n        'domain_filter'             => '(\&(objectclass=domainrelatedobject)(associateddomain=%s))',\n        'domain_name_attr'          => 'associateddomain',#g" /etc/roundcubemail/kolab_auth.inc.php
sed -r -i -e "s#'ou=People,.*'#'ou=People,%dc'#g" /etc/roundcubemail/kolab_auth.inc.php
sed -r -i -e "s#'ou=Groups,.*'#'ou=Groups,%dc'#g" /etc/roundcubemail/kolab_auth.inc.php

#####################################################################################
# Fix Global Address Book in Multi Domain environment
####################################################################################
cp -r /etc/roundcubemail/config.inc.php /etc/roundcubemail/config.inc.php.beforeMultiDomain
sed -r -i -e "s#'ou=People,.*'#'ou=People,%dc'#g" /etc/roundcubemail/config.inc.php
sed -r -i -e "s#'ou=Groups,.*'#'ou=Groups,%dc'#g" /etc/roundcubemail/config.inc.php
 
#####################################################################################
#fix a problem with kolab lm, see http://lists.kolab.org/pipermail/devel/2013-June/014435.html
#####################################################################################
sed -r -i -e "s/kolab_user_filter = /#kolab_user_filter = /g" /etc/kolab/kolab.conf

#####################################################################################
#set primary_mail value in kolab section, so that new users in a different domain will have a proper primary email address, even without changing kolab.conf for each domain
#####################################################################################
sed -r -i -e "s/\[kolab\]/[kolab]\nprimary_mail = %(givenname)s.%(surname)s@%(domain)s/g" /etc/kolab/kolab.conf

#####################################################################################
#set the domain for management of the domain admins, and add new user_type domainadmin
#####################################################################################
sed -r -i -e "s/\[kolab\]/[kolab]\ndomainadmins_management_domain = _domainadmins.org/g" /etc/kolab/kolab.conf
sed -r -i -e "s/\[kolab\]/[kolab]\ndomainadmin_quota_attribute = tbitskolaboverallquota/g" /etc/kolab/kolab.conf
sed -r -i -e 's/config_set\("debug", true\)/config_set("debug", false)/g' /usr/share/kolab-webadmin/lib/Auth/LDAP.php
php initDomainAdminManagementDomain.php
#sed -r -i -e 's/config_set\("debug", false\)/config_set("debug", true)/g' /usr/share/kolab-webadmin/lib/Auth/LDAP.php

#####################################################################################
# apply a couple of patches, see related kolab bugzilla number in filename, eg. https://issues.kolab.org/show_bug.cgi?id=2018
#####################################################################################
yum -y install wget patch

if [ ! -d patches ]
then
  mkdir -p patches
  echo Downloading patch patchMultiDomainAdminsBug2018.patch...
  wget https://raw.github.com/tpokorra/kolab3_tbits_scripts/master/kolab3.1/patches/patchMultiDomainAdminsBug2018.patch -O patches/patchMultiDomainAdminsBug2018.patch
  echo Downloading patch domainquotaBug2046.patch...
  wget https://raw.github.com/tpokorra/kolab3_tbits_scripts/master/kolab3.1/patches/domainquotaBug2046.patch -O patches/domainquotaBug2046.patch
  echo Downloading patch  deleteDomainWithUsersBug1869.patch
  wget https://raw.github.com/tpokorra/kolab3_tbits_scripts/master/kolab3.1/patches/deleteDomainWithUsersBug1869.patch -O patches/deleteDomainWithUsersBug1869.patch
  echo Downloading patch checkboxLDAPBug2452.patch
  wget https://raw.github.com/tpokorra/kolab3_tbits_scripts/master/kolab3.1/patches/checkboxLDAPBug2452.patch -O patches/checkboxLDAPBug2452.patch
  echo Downloading patch patchDomainAdminAccountLimitations.patch
  wget https://raw.github.com/tpokorra/kolab3_tbits_scripts/master/kolab3.1/patches/patchDomainAdminAccountLimitations.patch -O patches/patchDomainAdminAccountLimitations.patch
fi

patch -p1 -i `pwd`/patches/patchMultiDomainAdminsBug2018.patch -d /usr/share/kolab-webadmin
patch -p1 -i `pwd`/patches/domainquotaBug2046.patch -d /usr/share/kolab-webadmin
patch -p1 -i `pwd`/patches/deleteDomainWithUsersBug1869.patch -d /usr/share/kolab-webadmin
patch -p0 -i `pwd`/patches/checkboxLDAPBug2452.patch
patch -p0 -i `pwd`/patches/patchDomainAdminAccountLimitations.patch

