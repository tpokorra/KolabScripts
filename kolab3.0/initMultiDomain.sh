#!/bin/bash
#Removing Canonification from Cyrus IMAP
# TODO: could preserve canonification: http://www.intevation.de/pipermail/kolab-users/2012-August/013747.html
sed -r -i -e 's/^auth_mech/#auth_mech/g' /etc/imapd.conf
sed -r -i -e 's/^pts_module/#pts_module/g' /etc/imapd.conf
sed -r -i -e 's/^ldap_/#ldap_/g' /etc/imapd.conf
service cyrus-imapd restart
 
patch -p1 -d /usr/share/kolab-webadmin < patches/patchMultiDomainAdminsBug2018.patch
patch -p1 -d /usr/share/kolab-webadmin < patches/mailquotaBug1966.patch
patch -p1 -d /usr/share/kolab-webadmin < patches/validationOptionalValuesBug2045.patch
patch -p1 -d /usr/share/kolab-webadmin < patches/mailquotaBug1966.patch
