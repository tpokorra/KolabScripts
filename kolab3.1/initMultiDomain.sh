#Removing Canonification from Cyrus IMAP
# TODO: could preserve canonification: http://www.intevation.de/pipermail/kolab-users/2012-August/013747.html
sed -r -i -e 's/^auth_mech/#auth_mech/g' /etc/imapd.conf
sed -r -i -e 's/^pts_module/#pts_module/g' /etc/imapd.conf
sed -r -i -e 's/^ldap_/#ldap_/g' /etc/imapd.conf
service cyrus-imapd restart
 
#kolab_auth conf roundcube
sed -r -i -e "s#=> 389,#=> 389,\n        'domain_base_dn'            => 'cn=kolab,cn=config',\n        'domain_filter'             => '(\&(objectclass=domainrelatedobject)(associateddomain=%s))',\n        'domain_name_attr'          => 'associateddomain',#g" kolab_auth.inc.php
sed -r -i -e "s#'ou=People,.*'#'ou=People,%dc'#g" /etc/roundcubemail/kolab_auth.inc.php
sed -r -i -e "s#'ou=Groups,.*'#'ou=Groups,%dc'#g" /etc/roundcubemail/kolab_auth.inc.php
 
#fix a problem with kolab lm, see http://www.intevation.de/pipermail/kolab-devel/2013-June/014492.html
sed -r -i -e "s/kolab_user_filter = /#kolab_user_filter = /g" /etc/kolab/kolab.conf
