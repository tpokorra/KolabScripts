#!/bin/bash

#####################################################################################
# adjust some settings, that might be specific to TBits
#####################################################################################
service kolabd stop
service kolab-saslauthd stop

# add admin_auto_fields_rw = true to kolab_wap section of kolab.conf
sed -r -i -e "s#\[kolab_wap\]#[kolab_wap]\nadmin_auto_fields_rw = true#g" /etc/kolab/kolab.conf

# change default locale
sed -r -i -e "s#default_locale = en_US#default_locale = de_DE#g" /etc/kolab/kolab.conf

# set in kolab.conf, ldap section: modifytimestamp_format = %%Y%%m%%d%%H%%M%%SZ, to avoid warning on console
sed -r -i -e "s#\[ldap\]#[ldap]\nmodifytimestamp_format = %%Y%%m%%d%%H%%M%%SZ#g" /etc/kolab/kolab.conf

# set in /etc/sysconfig/dirsrv: ulimit -n 32192, to avoid dirsrv crashing because of too many open files
sed -r -i -e "s/# ulimit -n 8192/ulimit -n 32192/g" /etc/sysconfig/dirsrv
service dirsrv restart

# disable debug mode in LDAP.php to avoid too much output
sed -r -i -e 's/config_set\("debug", true\)/config_set("debug", false)/g' /usr/share/kolab-webadmin/lib/Auth/LDAP.php
# disable debug modes for roundcube; otherwise /var/log/roundcubemail/imap can get really big!
sed -r -i -e "s/_debug'] = true/_debug'] = false/g" /etc/roundcubemail/config.inc.php

# change order of addressbooks: first personal address book
sed -r -i -e "s# = 0;# = 1;#g" /etc/roundcubemail/kolab_addressbook.inc.php

# change default names for calendar and address book
sed -r -i -e "s#Calendar#Kalender#g" /etc/roundcubemail/kolab_folders.inc.php
sed -r -i -e "s#Contacts#Kontakte#g" /etc/roundcubemail/kolab_folders.inc.php
sed -r -i -e "s#Sent#Gesendet#g" /etc/roundcubemail/kolab_folders.inc.php
sed -r -i -e "s#Drafts#Entwürfe#g" /etc/roundcubemail/kolab_folders.inc.php
sed -r -i -e "s#Trash#Papierkorb#g" /etc/roundcubemail/kolab_folders.inc.php
#sed -r -i -e "s#Spam#Spam#g" /etc/roundcubemail/kolab_folders.inc.php
sed -r -i -e "s#kolab_folders_task_default'\] = ''#kolab_folders_task_default'] = 'Aufgaben'#g" /etc/roundcubemail/kolab_folders.inc.php
sed -r -i -e "s#kolab_folders_note_default'\] = ''#kolab_folders_note_default'] = 'Notizen'#g" /etc/roundcubemail/kolab_folders.inc.php
#sed -r -i -e "s#kolab_folders_journal_default'\] = ''#kolab_folders_journal_default'] = 'Journal'#g" /etc/roundcubemail/kolab_folders.inc.php

sed -r -i -e "s#'Calendar'#'Kalender'#g" /etc/kolab/kolab.conf
sed -r -i -e "s#'Contacts'#'Kontakte'#g" /etc/kolab/kolab.conf
sed -r -i -e "s#'Sent'#'Gesendet'#g" /etc/kolab/kolab.conf
sed -r -i -e "s#'Drafts'#'Entwürfe'#g" /etc/kolab/kolab.conf
sed -r -i -e "s#'Trash'#'Papierkorb'#g" /etc/kolab/kolab.conf
sed -r -i -e "s#'Tasks'#'Aufgaben'#g" /etc/kolab/kolab.conf
sed -r -i -e "s#'Notes'#'Notizen'#g" /etc/kolab/kolab.conf

# change default language
sed -r -i -e "s#// Re-apply mandatory settings here.#// Re-apply mandatory settings here.\n    \$config['locale_string'] = 'de';#g" /etc/roundcubemail/config.inc.php

# make Kalender and Kontakte default folders in roundcube, so that they get subscribed automatically
#sed -r -i -e "s#'INBOX', 'Drafts', 'Sent', 'Spam', 'Trash'#'INBOX', 'Drafts', 'Sent', 'Spam', 'Trash', 'Kalender', 'Kontakte'#g" /etc/roundcubemail/config.inc.php
# enable plugin subscriptions_options (disabled, it does not seem to exist anymore)
# sed -r -i -e "s#'redundant_attachments',#'redundant_attachments',\n            'subscriptions_option',#g" /etc/roundcubemail/config.inc.php
#sed -r -i -e "s#// Re-apply mandatory settings here.#// Re-apply mandatory settings here.\n    \$config['use_subscriptions'] = false;#g" /etc/roundcubemail/config.inc.php

# disable files component for all users
# sed -r -i -e "s/'kolab_files',/#'kolab_files',/g" /etc/roundcubemail/config.inc.php

# remove personal calender from kolab.conf
rm -f /etc/kolab/kolab.conf.new
skip=0
# set internal file separator so that the leading spaces are not trimmed
OIFS=$IFS
IFS=
while read line
do
  if [[ $skip -gt 0 ]]
  then
    skip=$((skip-1))
    #echo $line
    continue;
  fi
  test=`echo $line | grep -e "Calendar/Personal Calendar" -e "Contacts/Personal Contacts" `
  if [[ ${#test} -gt 0 ]]
  then
    #echo $test;
    skip=4
    continue;
  fi
  echo $line >> /etc/kolab/kolab.conf.new
done < /etc/kolab/kolab.conf
IFS=$OIFS
mv /etc/kolab/kolab.conf.new /etc/kolab/kolab.conf

service kolabd start
service kolab-saslauthd start

