#!/bin/bash

#####################################################################################
# create a file that can be manipulated manually to allow aliases across domains
# (eg. user mymailbox@test.de gets emails that are sent to myalias@test2.de)
#
# You need to run postmap on the file after manually changing it!
#####################################################################################

filename=/etc/postfix/virtual_alias_maps_manual.cf
if [ ! -f $filename ]
then
    echo "# you can manually set aliases, across domains. " > $filename
    echo "# for example: " >> $filename
    echo "#myalias@test2.de mymailbox@test.de" >> $filename
    echo "#@pokorra.it timotheus.pokorra@test1.de" >> $filename
fi

sed -i -e "s#ldap:/etc/postfix/ldap/virtual_alias_maps.cf#ldap:/etc/postfix/ldap/virtual_alias_maps.cf, hash:$filename#" /etc/postfix/main.cf

postmap $filename
service postfix restart

