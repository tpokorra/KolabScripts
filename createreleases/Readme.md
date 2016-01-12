Build Instructions
======

This helps to build regular releases based on Kolab Development. The version scheme should contain the year and the month of the release, eg. Kolab-2016.02. This release can be done with a release candidate before the final release.

The script will download the source rpms from the Kolab Systems OBS, from the location http://obs.kolabsys.com/repositories/Kolab:/Development/CentOS_7/src/

It will process the source rpms, and adjust the spec files to modify the version of the packages.

* we want to see in the rpm package name the git version of the release.
* we want to see the Kolab release in the package name.

The script will push the package definition to Github, so that I can build the CentOS6 packages on LBS.

The script will upload the source rpms to FedoraPeople.org: https://tpokorra.fedorapeople.org/kolab/kolab-<releaseid>/<state>. sftp will use my private key stored at ~/.ssh/id_rsa

Then the script will install the source rpms, and check the spec files to determine the order in which the packages need to be built. Then it will print the packages that can be built in parallel, and which sets of packages must be built in that order.

If somebody else is using this script, you need to change the urls and usernames at the top of the script.

Then run:

    ./mirror_kolab_development.py 2015.2 RC1
    ./mirror_kolab_development.py 2015.2 final

Which will show which packages should be built together.

Paste these links at the copr build page: https://copr.fedoraproject.org/coprs/tpokorra/Kolab-3.5-Preparation/add_build/

And wait for the builds to finish, and then do the next block of packages.

Installing Kolab from the copr repositories
==

Now you can install Kolab from the copr repositories.

For CentOS7:

    yum install epel-release yum-plugin-priorities
    cd /etc/yum.repos.d/
    wget https://copr.fedoraproject.org/coprs/tpokorra/Kolab-3.5/repo/epel-7/tpokorra-Kolab-3.5-Preparation-epel-7.repo -O Kolab-3.5-Preparation.repo

    # Make sure that the packages from the Kolab repositories have a higher priority than eg. the Epel packages:
    for f in /etc/yum.repos.d/Kolab*.repo; do sed -i "s#enabled=1#enabled=1\npriority=1#g" $f; done
    
    yum install kolab
    
    # now follow the instructions at https://docs.kolab.org/installation-guide/setup-kolab.html#install-setup-kolab
