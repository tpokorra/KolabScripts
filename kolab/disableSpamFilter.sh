#!/bin/bash

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

DetermineOS
InstallWgetAndPatch
DeterminePythonPath

#####################################################################################
# disable the spam filter, if it is not needed
#####################################################################################

echo "disabling amavis and clamd"
patch -p1 -i `pwd`/patches/disableSpamFilter.patch -d $pythonDistPackages || exit -1
patch -p1 -i `pwd`/patches/disableSpamFilter2.patch -d / || exit -1
