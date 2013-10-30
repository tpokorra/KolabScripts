#!/bin/bash

#####################################################################################
# apply a couple of patches, see related kolab bugzilla number in filename, eg. https://issues.kolab.org/show_bug.cgi?id=2018
#####################################################################################
patch -p1 -i `pwd`/patches/patchMultiDomainAdminsBug2018.patch -d /usr/share/kolab-webadmin
patch -p1 -i `pwd`/patches/domainquotaBug2046.patch -d /usr/share/kolab-webadmin
patch -p1 -i `pwd`/patches/deleteDomainWithUsersBug1869.patch -d /usr/share/kolab-webadmin
patch -p0 -i `pwd`/patches/checkboxLDAPBug2452.patch
patch -p0 -i `pwd`/patches/patchDomainAdminAccountLimitations.patch
