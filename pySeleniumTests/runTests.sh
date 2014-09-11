#!/bin/bash

# running all Unit tests that are working
tests="all"

if [ ! -z "$1" ]; then
  tests=$1
fi

rm -f /tmp/output*.html
hasError=0

# run tests against a vanilla Kolab
if [[ "$tests" == "all" || "$tests" == "vanilla" ]]; then
  ./testCreateUserAndEditSelf.py KolabWAPCreateUserAndEditSelf.test_edit_user_himself || hasError=1
  ./testRoundcubeChangePassword.py KolabRoundcubeChangePassword.test_edit_user_password || hasError=1
  ./testAutoCreateFolders.py KolabAutoCreateFolders.test_modified_foldername || hasError=1
  ./testEmailSendAndReceive.py || hasError=1
  ./testEmailSharedFolders.py || hasError=1
fi

# requires configuration for catchall and forwarding, and multidomain
if [[ "$tests" == "all" || "$tests" == "catchallforwarding" ]]; then
  # we need the multidomain script and patches installed, because otherwise we need to wait for up to 10 minutes for the domain sync to happen
  ./testEmailCatchAll.py || hasError=1
  # ignore other test test_mail_forwarding_external because it needs configuration of a domain that can receive email from outside
  ./testEmailForwarding.py KolabEmailMailForwarding.test_mail_forwarding || hasError=1
fi

# requires multi domain patch
if [[ "$tests" == "all" || "$tests" == "multidomain" ]]; then
  # these tests have been run in vanilla, but this time we run all test cases, and with SSL
  ./testCreateUserAndEditSelf.py || hasError=1
  ./testRoundcubeChangePassword.py || hasError=1
  ./testAutoCreateFolders.py || hasError=1

  ./testEmailCatchAllAcrossDomains.py || hasError=1
fi

# requires domain admin patch
if [[ "$tests" == "all" || "$tests" == "domainadmin" ]]; then
  ./testDomainAdmin.py || hasError=1
  ./testDomainAdminDefaultQuota.py || hasError=1
  ./testDomainAdminMaxAccounts.py || hasError=1
  ./testDomainAdminOverallQuota.py || hasError=1
  ./testLastLogin.py || hasError=1
fi

exit $hasError
