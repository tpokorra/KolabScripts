#!/bin/bash

if ( which yum ); then
  yum -y install wget patch
else
  if (which apt-get); then
    apt-get -y install wget patch;
  else echo "Neither yum nor apt-get available. On which platform are you?";
  exit 0
  fi
fi

#####################################################################################
#Removing Canonification from Cyrus IMAP
# TODO: could preserve canonification: http://lists.kolab.org/pipermail/users/2012-August/013711.html
# but that would mean that we need separate files for each domain...
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
for f in `find /etc/postfix/ldap/ -type f -name "*.cf"`;
do
  f3=${f/.cf/_3.cf}
  cp $f $f3
  if [[ "/etc/postfix/ldap/mydestination.cf" == "$f" ]]
  then
    sed -r -i -e 's/^query_filter = .*$/query_filter = (\&(associateddomain=%s)(associateddomain=*.*.*))/g' $f3
  else
    sed -r -i -e 's/^search_base = .*$/search_base = dc=%2,dc=%1/g' $f
    sed -r -i -e 's/^search_base = .*$/search_base = dc=%3,dc=%2,dc=%1/g' $f3
    sed -r -i -e 's#^domain = .*$#domain = ldap:/etc/postfix/ldap/mydestination_3.cf#g' $f3
  fi
done

cp -f /etc/postfix/main.cf /etc/postfix/main.cf.beforeMultiDomain
sed -r -i -e 's#transport_maps.cf#transport_maps.cf, ldap:/etc/postfix/ldap/transport_maps_3.cf#g' /etc/postfix/main.cf
sed -i -e 's#virtual_alias_maps.cf#virtual_alias_maps.cf, ldap:/etc/postfix/ldap/virtual_alias_maps_3.cf, ldap:/etc/postfix/ldap/mailenabled_distgroups_3.cf, ldap:/etc/postfix/ldap/mailenabled_dynamic_distgroups_3.cf, ldap:/etc/postfix/ldap/virtual_alias_maps_sharedfolders_3.cf#' /etc/postfix/main.cf
sed -r -i -e 's#local_recipient_maps.cf#local_recipient_maps.cf, ldap:/etc/postfix/ldap/local_recipient_maps_3.cf#g' /etc/postfix/main.cf

# create a file that can be manipulated manually to allow aliases across domains;
# eg. user mymailbox@test.de gets emails that are sent to myalias@test2.de;
# You can also enable aliases for domains here to receive emails properly, eg. @test2.de @test.de;
# You need to run postmap on the file after manually changing it!
postfix_virtual_file=/etc/postfix/virtual_alias_maps_manual.cf
if [ ! -f $postfix_virtual_file ]
then
    echo "# you can manually set aliases, across domains. " > $postfix_virtual_file
    echo "# for example: " >> $postfix_virtual_file
    echo "#myalias@test2.de mymailbox@test.de" >> $postfix_virtual_file
    echo "#@test4.de @test.de" >> $postfix_virtual_file
    echo "#@pokorra.it timotheus.pokorra@test1.de" >> $postfix_virtual_file
fi
sed -i -e "s#virtual_alias_maps.cf#virtual_alias_maps.cf, hash:$postfix_virtual_file#" /etc/postfix/main.cf
postmap $postfix_virtual_file

service postfix restart

#####################################################################################
#kolab_auth conf roundcube; see https://git.kolab.org/roundcubemail-plugins-kolab/commit/?id=1778b5ec70156f064fdda61c817c678001406996
#####################################################################################
cp -r /etc/roundcubemail/kolab_auth.inc.php /etc/roundcubemail/kolab_auth.inc.php.beforeMultiDomain
sed -r -i -e "s#=> 389,#=> 389,\n        'domain_base_dn'            => 'cn=kolab,cn=config',\n        'domain_filter'             => '(\&(objectclass=domainrelatedobject)(associateddomain=%s))',\n        'domain_name_attr'          => 'associateddomain',#g" /etc/roundcubemail/kolab_auth.inc.php
sed -r -i -e "s#'ou=People,.*'#'ou=People,%dc'#g" /etc/roundcubemail/kolab_auth.inc.php
sed -r -i -e "s#'ou=Groups,.*'#'ou=Groups,%dc'#g" /etc/roundcubemail/kolab_auth.inc.php

#####################################################################################
#fix a bug https://issues.kolab.org/show_bug.cgi?id=2673 
#so that changing the password works in Roundcube for multiple domains
#####################################################################################
cp -r /etc/roundcubemail/password.inc.php /etc/roundcubemail/password.inc.php.beforeMultiDomain
sed -r -i -e "s#config\['password_driver'\] = 'ldap'#config['password_driver'] = 'ldap_simple'#g" /etc/roundcubemail/password.inc.php

#####################################################################################
#enable freebusy for all domains
#####################################################################################
sed -r -i -e "s#base_dn = .*#base_dn = %dc#g" /usr/share/kolab-freebusy/config/config.ini

#####################################################################################
#fix a bug for freebusy (see https://issues.kolab.org/show_bug.cgi?id=2524, missing quotes)
#####################################################################################
sed -r -i -e 's#bind_dn = (.*)#bind_dn = "\1"#g' /usr/share/kolab-freebusy/config/config.ini


#####################################################################################
# Fix Global Address Book in Multi Domain environment
####################################################################################
cp -r /etc/roundcubemail/config.inc.php /etc/roundcubemail/config.inc.php.beforeMultiDomain
sed -r -i -e "s#'ou=People,.*'#'ou=People,%dc'#g" /etc/roundcubemail/config.inc.php
sed -r -i -e "s#'ou=Groups,.*'#'ou=Groups,%dc'#g" /etc/roundcubemail/config.inc.php
 
#####################################################################################
#set primary_mail value in kolab section, so that new users in a different domain will have a proper primary email address, even without changing kolab.conf for each domain
#####################################################################################
sed -r -i -e "s/primary_mail = .*/primary_mail = %(givenname)s.%(surname)s@%(domain)s/g" /etc/kolab/kolab.conf

#####################################################################################
#reduce the sleep time between adding domains, see https://issues.kolab.org/show_bug.cgi?id=2491
#####################################################################################
sed -r -i -e "s/\[kolab\]/[kolab]\nsleep_between_domain_operations_in_seconds = 10/g" /etc/kolab/kolab.conf

#####################################################################################
#make sure that for alias domains, the emails will actually arrive, by checking the postfix file
#see https://issues.kolab.org/show_bug.cgi?id=2658
#####################################################################################
sed -r -i -e "s#\[kolab\]#[kolab]\npostfix_virtual_file = $postfix_virtual_file#g" /etc/kolab/kolab.conf

#####################################################################################
#avoid a couple of warnings by setting default values
#####################################################################################
sed -r -i -e "s#\[ldap\]#[ldap]\nmodifytimestamp_format = %%Y%%m%%d%%H%%M%%SZ#g" /etc/kolab/kolab.conf
sed -r -i -e "s/\[cyrus-imap\]/[imap]\nvirtual_domains = userid\n[cyrus-imap]/g" /etc/kolab/kolab.conf

#####################################################################################
# apply a couple of patches, see related kolab bugzilla number in filename, eg. https://issues.kolab.org/show_bug.cgi?id=1869
#####################################################################################

if [ ! -d patches ]
then
  mkdir -p patches
  echo Downloading patch  deleteDomainWithUsersBug1869.patch
  wget https://raw.github.com/tpokorra/kolab3_tbits_scripts/master/kolab3.1/patches/deleteDomainWithUsersBug1869.patch -O patches/deleteDomainWithUsersBug1869.patch
  echo Downloading patch  sleepTimeBetweenDomainOperationsBug2491.patch
  wget https://raw.github.com/tpokorra/kolab3_tbits_scripts/master/kolab3.1/patches/sleepTimeBetweenDomainOperationsBug2491.patch -O patches/sleepTimeBetweenDomainOperationsBug2491.patch
  echo Downloading patch freebusyMultiDomainBug2630.patch
  wget https://raw.github.com/tpokorra/kolab3_tbits_scripts/master/kolab3.1/patches/freebusyMultiDomainBug2630.patch -O patches/freebusyMultiDomainBug2630.patch
  echo Downloading patch validateAliasDomainPostfixVirtualFileBug2658.patch
  wget https://raw.github.com/tpokorra/kolab3_tbits_scripts/master/kolab3.1/patches/validateAliasDomainPostfixVirtualFileBug2658.patch -O patches/validateAliasDomainPostfixVirtualFileBug2658.patch
  echo Downloading patch fixLDAPPermissionsForSelfBug2678.patch
  wget https://raw.github.com/tpokorra/kolab3_tbits_scripts/master/kolab3.1/patches/fixLDAPPermissionsForSelfBug2678.patch -O patches/fixLDAPPermissionsForSelfBug2678.patch
fi

# different paths in debian and centOS
pythonDistPackages=/usr/lib/python2.7/dist-packages
# Debian
if [ ! -d $pythonDistPackages ]; then
  # centOS
  pythonDistPackages=/usr/lib/python2.6/site-packages
fi

patch -p1 -i `pwd`/patches/deleteDomainWithUsersBug1869.patch -d /usr/share/kolab-webadmin
patch -p1 -i `pwd`/patches/sleepTimeBetweenDomainOperationsBug2491.patch -d $pythonDistPackages
patch -p1 -i `pwd`/patches/freebusyMultiDomainBug2630.patch -d /usr/share/kolab-freebusy
patch -p1 -i `pwd`/patches/validateAliasDomainPostfixVirtualFileBug2658.patch -d /usr/share/kolab-webadmin
patch -p1 -i `pwd`/patches/fixLDAPPermissionsForSelfBug2678.patch -d /usr/share/kolab-webadmin

