#!/bin/bash

if [ `which yum` ]; then
  if [[ ! `which wget` || ! `which patch` ]]; then
    yum -y install wget patch
  fi
else
  if [ `which apt-get` ]; then
    if [[ ! `which wget` || ! `which patch` ]]; then
      apt-get -y install wget patch;
    fi
  else echo "Neither yum nor apt-get available. On which platform are you?";
  exit 0
  fi
fi

# disable the message_label plugin, because Kolab 3.3 has tags for emails
if [ 1 -eq 0 ];
then
#####################################################################################
# install our modified version of the message_label plugin to support virtual folders aka imap flags
# see  https://github.com/tpokorra/message_label/tree/message_label_tbits
#####################################################################################
wget https://github.com/tpokorra/message_label/archive/message_label_tbits.tar.gz -O message_label.tar.gz
tar -xzf message_label.tar.gz
rm -f message_label.tar.gz
mv message_label-message_label_tbits /usr/share/roundcubemail/plugins/message_label
cp -f /etc/roundcubemail/config.inc.php /etc/roundcubemail/config.inc.php.beforeMultiDomain
sed -r -i -e "s#'redundant_attachments',#'redundant_attachments',\n            'message_label',#g" /etc/roundcubemail/config.inc.php
# probably a dirty hack: we need to force fetching the headers, so that the labels are always displayed
cp -f /usr/share/roundcubemail/program/lib/Roundcube/rcube_imap.php /usr/share/roundcubemail/program/lib/Roundcube/rcube_imap.php.beforeMultiDOmain
sed -i -e 's#function fetch_headers($folder, $msgs, $sort = true, $force = false)#function fetch_headers($folder, $msgs, $sort = true, $forcedummy = false, $force = true)#g' /usr/share/roundcubemail/program/lib/Roundcube/rcube_imap.php

#####################################################################################
# apply a patch to roundcube plugin managesieve, to support the labels set with message_label plugin.
# see https://github.com/tpokorra/roundcubemail/commits/manage_sieve_using_message_label_flags
#####################################################################################
mkdir -p patches
echo Downloading patch managesieveWithMessagelabel.patch...
wget https://raw.github.com/tpokorra/kolab3_tbits_scripts/master/kolab3.1/patches/managesieveWithMessagelabel.patch
mv managesieveWithMessagelabel.patch patches/
patch -p1 -i `pwd`/patches/managesieveWithMessagelabel.patch -d /usr/share/roundcubemail
fi

#####################################################################################
# install the advanced_search plugin
# see https://github.com/GMS-SA/roundcube-advanced-search
#####################################################################################
wget https://github.com/GMS-SA/roundcube-advanced-search/archive/stable.tar.gz -O advanced_search.tar.gz
tar -xzf advanced_search.tar.gz
rm -f advanced_search.tar.gz
#pluginsPath=/usr/share/roundcubemail/public_html/assets/plugins
pluginsPath=/usr/share/roundcubemail/plugins
mv roundcube-advanced-search-stable $pluginsPath/advanced_search
mv $pluginsPath/advanced_search/config-default.inc.php $pluginsPath/advanced_search/config.inc.php
sed -r -i -e "s#messagemenu#toolbar#g" $pluginsPath/advanced_search/config.inc.php
sed -r -i -e "s#'redundant_attachments',#'redundant_attachments',\n            'advanced_search',#g" /etc/roundcubemail/config.inc.php

