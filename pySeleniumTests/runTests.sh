#!/bin/bash

# running all Unit tests that are working
tests="all"

if [ ! -z "$1" ]; then
  tests=$1
fi

# delete created domains starting with domain*
function deleteDomains() {
    for d in `kolab list-domains | grep -v "Primary Domain" | grep "^domain"`
    do
      kolab delete-domain --force $d
      php /usr/share/kolab-webadmin/bin/purge-deleted-domains
    done
    systemctl restart dirsrv.target
    systemctl restart httpd
    sleep 5
}

rm -f /tmp/output*.html

if [ ! -d /tmp/SeleniumTests ]
then
  xvfb-run firefox -CreateProfile "SeleniumTests /tmp/SeleniumTests"
fi

hasError=0

# run tests against a vanilla Kolab
if [[ "$tests" == "all" || "$tests" == "vanilla" ]]; then
  deleteDomains
  ./testCreateUserAndEditSelf.py KolabWAPCreateUserAndEditSelf.test_edit_user_himself || hasError=1
  ./testRoundcubeChangePassword.py KolabRoundcubeChangePassword.test_edit_user_password || hasError=1
  ./testAutoCreateFolders.py KolabAutoCreateFolders.test_modified_foldername || hasError=1
  ./testEmailSendAndReceive.py || hasError=1
  ./testEmailSharedFolders.py || hasError=1
fi

# requires configuration for catchall and forwarding, and multidomain
if [[ "$tests" == "all" || "$tests" == "catchallforwarding" ]]; then
  deleteDomains
  # we need the multidomain script and patches installed, because otherwise we need to wait for up to 10 minutes for the domain sync to happen
  ./testEmailCatchAll.py || hasError=1
  # ignore other test test_mail_forwarding_external because it needs configuration of a domain that can receive email from outside
  ./testEmailForwarding.py KolabEmailMailForwarding.test_mail_forwarding || hasError=1
fi

# requires multi domain patch
if [[ "$tests" == "all" || "$tests" == "multidomain" ]]; then
  deleteDomains
  # these tests have been run in vanilla, but this time we run all test cases, and with SSL
  ./testCreateUserAndEditSelf.py || hasError=1
  ./testRoundcubeChangePassword.py || hasError=1
  deleteDomains
  ./testAutoCreateFolders.py || hasError=1
  ./testUIDAcrossDomains.py || hasError=1

  deleteDomains
  ./testEmailCatchAllAcrossDomains.py || hasError=1
fi

# requires domain admin patch
if [[ "$tests" == "all" || "$tests" == "domainadmin" ]]; then
  deleteDomains
  ./testDomainAdmin.py || hasError=1
  ./testDomainAdminDefaultQuota.py || hasError=1
  ./testDomainAdminMaxAccounts.py || hasError=1
  ./testDomainAdminOverallQuota.py || hasError=1
  deleteDomains
  ./testLastLogin.py || hasError=1
  ./testListUsersQuota.py || hasError=1
fi

# check if kolab sync runs without error (see https://issues.kolab.org/show_bug.cgi?id=4847)
if [ $hasError -ne 1 ]; then
 if [[ "$tests" == "all" || "$tests" == "kolabsync" ]]; then
  if [ -f /bin/systemctl ]
  then
    /bin/systemctl stop kolabd.service
  elif [ -f /sbin/service ]
  then
    service kolabd stop
  elif [ -f /usr/sbin/service ]
  then
    service kolab-server stop
  fi

  kolab -d 9 sync 2>&1 | tee kolab-sync.log
  if [[ "`cat kolab-sync.log | grep UnicodeDecodeError`" != "" ]]
  then
    hasError=1
  fi

  if [ -f /bin/systemctl ]
  then
    /bin/systemctl start kolabd.service
  elif [ -f /sbin/service ]
  then
    service kolabd start
  elif [ -f /usr/sbin/service ]
  then
    service kolab-server start
  fi
 fi
fi

exit $hasError
