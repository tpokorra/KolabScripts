#!/bin/bash

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

DetermineOS
InstallWgetAndPatch
DeterminePythonPath

############################################
# disable guam if it does not work
# eg https://git.kolab.org/T1305
############################################

systemctl stop guam
systemctl disable guam

systemctl stop cyrus-imapd

# make sure that cyrus is listening on 993 and 143 instead of 9993
sed -r -i \
    -e 's#imaps.*9993.*#imap                cmd="imapd" listen="imap" prefork=5\n    imaps               cmd="imapd -s" listen="imaps" prefork=1#g' \
    /etc/cyrus.conf

systemctl start cyrus-imapd
