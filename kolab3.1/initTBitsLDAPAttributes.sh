#!/bin/bash

if [ ! -d patches ]
then
  mkdir -p patches
  echo Downloading patch patchTBitsLDAPAttributes.patch...
  wget https://raw.github.com/tpokorra/kolab3_tbits_scripts/master/kolab3.1/patches/99tbits.ldif -O patches/99tbits.ldif
fi

for d in /etc/dirsrv/slapd*
do
  cp patches/99tbits.ldif $d/schema/
done

service dirsrv restart
