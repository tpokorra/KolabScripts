Build Instructions
======

Run this script mirror_packages_from_obs_to_copr.py once for the release, and then for the updates.

The script will download the source rpms from the Kolab Systems OBS, from the locations http://obs.kolabsys.com/repositories/Kolab:/3.4/CentOS_7/src/ and http://obs.kolabsys.com/repositories/Kolab:/3.4:/Updates/CentOS_7/src/

Then the script will upload them to my webspace at FedoraPeople.org: https://tpokorra.fedorapeople.org/kolab/kolab-3.4/ and https://tpokorra.fedorapeople.org/kolab/kolab-3.4-updates/. sftp will use my private key stored at ~/.ssh/id_rsa

Then the script will install the source rpms, and check the spec files to determine the order in which the packages need to be built. Then it will print the packages that can be built in parallel, and which sets of packages must be built in that order.

If somebody else is using this script, you need to change the urls and usernames at the top of the script.

Then run:

    ./mirror_packages_from_obs_to_copr.py 3.4

Which will show this output:

    build together: 
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/kolab-autodiscover-0.1-4.1.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/kolab-schema-3.2-2.1.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/xsd-3.3.0.1-26.1.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/php-pear-Net-LDAP2-2.0.12-20.1.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/python-icalendar-3.8.2-7.1.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/kolab-3.1.9-3.1.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/libcalendaring-4.9.1-1.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/roundcubemail-plugin-dblog-2.0-21.1.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/php-Net-LDAP3-1.0.2-2.1.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/php-ZendFramework-1.12.5-11.1.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/swig-2.0.11-10.1.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/kolab-webadmin-3.2.6-4.1.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/python-cssmin-0.2.0-10.1.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/roundcubemail-plugin-composeaddressbook-5.0-24.1.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/xapian-core-1.2.16-6.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/mozldap-6.0.5-37.1.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/roundcubemail-plugin-converse-0.0-13.1.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/roundcubemail-skin-chameleon-0.3.5-2.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/python-sievelib-0.5.2-13.1.el7.kolab_3.4.src.rpm
    
    build together: 
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/cyrus-imapd-2.5-108.1.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/roundcubemail-plugin-contextmenu-2.1-5.1.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/libkolabxml-1.1.git.1422810799-29.1.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/roundcubemail-1.1.0-4.4.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/roundcubemail-plugins-kolab-3.2.7-1.el7.kolab_3.4.src.rpm
    
    build together: 
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/libkolab-0.6.git.1424348636-2.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/kolab-syncroton-2.3.1-4.1.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/pykolab-0.7.10-1.el7.kolab_3.4.src.rpm
    
    build together: 
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/kolab-freebusy-1.0.7-2.2.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/chwala-0.3.0-8.1.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/kolab-utils-3.1-14.1.el7.kolab_3.4.src.rpm
    
    build together: 
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4/iRony-0.3.0-3.1.el7.kolab_3.4.src.rpm

Paste these links at the copr build page: https://copr.fedoraproject.org/coprs/tpokorra/Kolab-3.4/add_build/

After the packages have been built successfull, do the same for the updates:

    ./mirror_packages_from_obs_to_copr.py 3.4-updates

Which will show this output:

    build together: 
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4-updates/roundcubemail-plugins-kolab-3.2.7-10.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4-updates/libcalendaring-4.9.1-4.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4-updates/kolab-3.1.9-3.4.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4-updates/kolab-webadmin-3.2.6-4.5.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4-updates/pykolab-0.7.10-4.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4-updates/roundcubemail-1.1.3-4.9.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4-updates/cyrus-imapd-2.5-108.3.el7.kolab_3.4.src.rpm
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4-updates/roundcubemail-plugin-contextmenu-2.1.1-5.3.el7.kolab_3.4.src.rpm

    build together: 
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4-updates/libkolab-0.6.0-3.el7.kolab_3.4.src.rpm

    build together: 
    https://tpokorra.fedorapeople.org/kolab/kolab-3.4-updates/kolab-utils-3.1-14.3.el7.kolab_3.4.src.rpm

Paste these links here: https://copr.fedoraproject.org/coprs/tpokorra/Kolab-3.4-Updates/add_build/

And wait for the builds to finish.

Installing Kolab from the copr repositories
==

Now you can install Kolab from the copr repositories.

For CentOS6:

    yum install epel-release yum-plugin-priorities
    cd /etc/yum.repos.d/
    wget https://copr.fedoraproject.org/coprs/tpokorra/Kolab-3.4/repo/epel-6/tpokorra-Kolab-3.4-epel-6.repo -O Kolab-3.4.repo
    wget https://copr.fedoraproject.org/coprs/tpokorra/Kolab-3.4-Updates/repo/epel-6/tpokorra-Kolab-3.4-Updates-epel-6.repo -O Kolab-3.4-Updates.repo

    # Make sure that the packages from the Kolab repositories have a higher priority than eg. the Epel packages:
    for f in /etc/yum.repos.d/Kolab*.repo; do sed -i "s#enabled=1#enabled=1\npriority=1#g" $f; done
    
    yum install kolab
    
    # now follow the instructions at https://docs.kolab.org/installation-guide/setup-kolab.html#install-setup-kolab


For CentOS7:

    yum install epel-release yum-plugin-priorities
    cd /etc/yum.repos.d/
    wget https://copr.fedoraproject.org/coprs/tpokorra/Kolab-3.4/repo/epel-7/tpokorra-Kolab-3.4-epel-7.repo -O Kolab-3.4.repo
    wget https://copr.fedoraproject.org/coprs/tpokorra/Kolab-3.4-Updates/repo/epel-7/tpokorra-Kolab-3.4-Updates-epel-7.repo -O Kolab-3.4-Updates.repo

    # Make sure that the packages from the Kolab repositories have a higher priority than eg. the Epel packages:
    for f in /etc/yum.repos.d/Kolab*.repo; do sed -i "s#enabled=1#enabled=1\npriority=1#g" $f; done
    
    yum install kolab
    
    # now follow the instructions at https://docs.kolab.org/installation-guide/setup-kolab.html#install-setup-kolab

I am still working to fix the packages for Fedora 23.

Modifications needed for packages
==

For Kolab 3.4 and Kolab 3.4 Updates, I was able to use all source packages as they were from the KolabSystem OBS.

python-pyasn1
--
Only the source package python-pyasn1 is missing on the OBS for CentOS6. CentOS6 comes with a very old version of python-pyasn1 which does not build python-pyasn1-modules yet. But pykolab requires python-pyasn1-modules.

So I got the source package from CentOS7: http://vault.centos.org/7.2.1511/os/Source/SPackages/python-pyasn1-0.1.6-2.el7.src.rpm

It did not build on CentOS6, because the constant __python2 was not defined. I patched it like this:

```
--- SPECS/python-pyasn1.spec	2013-12-29 01:56:10.000000000 +0100
+++ SPECS/python-pyasn1.spec.new	2015-12-18 07:57:28.408316492 +0100
@@ -4,12 +4,16 @@
 %{!?python_sitelib: %global python_sitelib %(%{__python} -c "from distutils.sysconfig import get_python_lib; print (get_python_lib())")}
 %endif
 
+%if 0%{?rhel} < 7
+%global __python2 python2
+%endif
+
 %global module pyasn1
 %global modules_version 0.0.4
 
 Name:           python-pyasn1
 Version:        0.1.6
-Release:        2%{?dist}
+Release:        3%{?dist}
 Summary:        ASN.1 tools for Python
 License:        BSD
 Group:          System Environment/Libraries
@@ -135,6 +139,9 @@
 %endif
 
 %changelog
+* Fri Dec 18 2015 Timotheus Pokorra <tp@tbits.net> - 0.1.6-3
+- make it build on CentOS6
+
 * Fri Dec 27 2013 Daniel Mach <dmach@redhat.com> - 0.1.6-2
 - Mass rebuild 2013-12-27
```

CentOS6: upgraded packages php-pear-Mail-Mime, php-Smarty and python-ldap
--

When installing kolab on CentOS6, I realised that the Kolab OBS also provided newer versions of php-pear-Mail-Mime, php-Smarty and python-ldap. Unfortunately the source rpms are not available for download, but the SPEC files and the tarballs and patches are. So I built the source rpms without any modification and uploaded them to my webspace at FedoraPeople.org.
