#!/bin/bash

# remove canonification
# we can only keep canonification if Cyrus was built with the patch
# https://github.com/TBits/KolabScripts/blob/Kolab16/kolab/patches/cyrus_canonification_multiple_domains.patch
# which has been accepted upstream:
# https://github.com/cyrusimap/cyrus-imapd/commit/1e21647e0741b41c3607de54ab8cda6414deabaa#diff-a53b51d7c393e8407ee2e194ab397f0f

sed -i \
    -e 's/^auth_mech/#auth_mech/g' \
    -e 's/^pts_module/#pts_module/g' \
    -e 's/^ldap_/#ldap_/g' \
    /etc/imapd.conf
sed -i \
    -e 's/ptloader/#ptloader/g' \
    /etc/cyrus.conf

service cyrus-imapd restart
