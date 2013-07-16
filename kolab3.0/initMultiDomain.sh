#!/bin/bash
#Removing Canonification from Cyrus IMAP
# TODO: could preserve canonification: http://www.intevation.de/pipermail/kolab-users/2012-August/013747.html
sed -r -i -e 's/^auth_mech/#auth_mech/g' /etc/imapd.conf
sed -r -i -e 's/^pts_module/#pts_module/g' /etc/imapd.conf
sed -r -i -e 's/^ldap_/#ldap_/g' /etc/imapd.conf
service cyrus-imapd restart
 
patch -p0 -i `pwd`/patches/patchMultiDomainAdminsBug2018.patch  -d /usr/share/kolab-webadmin
patch -p0 -i `pwd`/patches/mailquotaBug1966.patch  -d /usr/share/kolab-webadmin
