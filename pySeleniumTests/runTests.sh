#!/bin/bash

# running all Unit tests that are working
tests="all"

if [ ! -z "$1" ]; then
  tests=$1
fi

rm -f /tmp/output*.html

# run tests against a vanilla Kolab
if [[ "$tests" == "all" || "$tests" == "vanilla" ]]; then
  ./testCreateUserAndEditSelf.py KolabWAPCreateUserAndEditSelf.test_edit_user_himself
  ./testRoundcubeChangePassword.py KolabRoundcubeChangePassword.test_edit_user_password
fi

# requires configuration for catchall and forwarding
if [[ "$tests" == "all" || "$tests" == "catchallforwarding" ]]; then 
  ./testEmailCatchAll.py
  ./testEmailForwarding.py
fi

# requires multi domain patch
if [[ "$tests" == "all" || "$tests" == "multidomain" ]]; then
  ./testCreateUserAndEditSelf.py
  ./testRoundcubeChangePassword.py
  ./testEmailCatchAllAcrossDomains.py
  ./testAutoCreateFolders.py
  ./testEmailSharedFolders.py
fi

# requires domain admin patch
if [[ "$tests" == "all" || "$tests" == "domainadmin" ]]; then
  ./testDomainAdmin.py
  ./testDomainAdminDefaultQuota.py
  ./testDomainAdminEnableGroupware.py
  ./testDomainAdminMaxAccounts.py
  ./testDomainAdminOverallQuota.py
fi

# disabled because it needs configuration of public email server
#./testEmailSendAndReceive.py

