#!/bin/bash
# run some tests against a vanilla kolab installation

# do a fresh install
if [ 1 -eq 0 ]
then
  cd ../kolab3.1
  echo "y" | ./reinstall.sh
  ./initSetupKolabPatches.sh
  setup-kolab --default --timezone=Europe/Berlin --directory-manager-pwd=test
  service kolabd restart
  ./initMultiDomain.sh
  ./initMailForward.sh
  ./initMailCatchall.sh
fi

# run the tests
cd ../pySeleniumTests
./testAutoCreateFolders.py
