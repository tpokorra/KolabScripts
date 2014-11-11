FROM centos:centos6
RUN mv /etc/localtime /etc/localtime.old; ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime
RUN echo "NAME=kolab33.test.example.org" > /etc/sysconfig/network
RUN echo "NETWORKING=yes" >> /etc/sysconfig/network
RUN chmod a+w /dev/shm
RUN sed -i "s/tsflags=nodocs/#tsflags=nodocs/g" /etc/yum.conf
RUN sed -i "s/%_excludedocs 1/#%_excludedocs 1/g" /etc/rpm/macros.imgcreate
WORKDIR /root
RUN yum -y install tar wget
RUN wget -O kolabscripts.tar.gz https://github.com/TBits/KolabScripts/archive/Kolab3.3.tar.gz; tar xzf kolabscripts.tar.gz; rm kolabscripts.tar.gz
WORKDIR /root/KolabScripts-Kolab3.3/kolab
RUN sed -i -e "s/^yum -y install kolab.*/#yum -y install kolab/" reinstallCentOS.sh
RUN echo "y" | ./reinstallCentOS.sh CentOS_6

#RUN yum -y install kolab
# split yum -y install kolab into several steps,
# to keep the revisions small enough to avoid problems with uploading the image
RUN yum -y install php-kolabformat
RUN yum -y install mysql-server
RUN yum -y install kolab-cli
RUN yum -y install kolab-imap
RUN yum -y install 389-ds-base
RUN yum -y install java-1.6.0-openjdk
RUN yum -y install libgcj
RUN yum -y install kolab-ldap
RUN yum -y install kolab-webadmin
RUN yum -y install iRony
RUN yum -y install wallace
RUN yum -y install kolab-webclient
RUN yum -y install postfix
RUN yum -y install clamd
RUN yum -y install kolab-mta
RUN yum -y install kolab patch unzip

# prepare for setup kolab
RUN ./initSetupKolabPatches.sh
# we cannot run setup-kolab here, because the hostname is no FQDN
# RUN echo 2 | setup-kolab --default --timezone=Europe/Brussels --directory-manager-pwd=test

RUN echo "#!/bin/bash" > /root/start.sh; echo "service httpd start" >> /root/start.sh; echo "service mysqld start" >> /root/start.sh; echo "service dirsrv start" >> /root/start.sh; echo "service cyrus-imapd start" >> /root/start.sh; echo "sleep 10" >> /root/start.sh; echo "service kolabd start" >> /root/start.sh; echo "service kolab-saslauthd start" >> /root/start.sh; chmod a+x /root/start.sh

RUN echo "#!/bin/bash" > /root/stop.sh; echo "service kolabd stop && service dirsrv stop && service cyrus-imapd stop && service mysqld stop && service httpd stop" >> /root/stop.sh; chmod a+x /root/stop.sh

# allow connections on port 443 (https)
EXPOSE 443
# TODO: allow IMAP as well

# Run manually inside the docker container:
#  echo `hostname -f` > /proc/sys/kernel/hostname
#  echo 2 | setup-kolab --default --timezone=Europe/Brussels --directory-manager-pwd=test
#  ./initHttpTunnel.sh
#  ./initSSL.sh test.example.org
#  /root/stop.sh
#  exit
 
