#!/bin/bash

if [ -z $1 ]
then
  echo "Please call: $0 <url of server>"
  echo "  eg. $0 example.org"
  exit 1
fi
export server_name=$1


#####################################################################################
# see also https://gist.github.com/dhoffend/7008915 with title: Simple SSL Configuration for Kolab 3.1
#####################################################################################

export key_directory=/etc/pki/tls
export sslgroup=ssl
export ca_file=startcom-ca.pem
export ca_subclass_file=startcom-sub.class2.server.ca.pem

if [ ! -d $key_directory ]
then
    # Debian: the keys live in a different place
    echo "Warning: this has not been tested for Debian yet!!!"
    key_directory=/etc/ssl
    sslgroup=ssl-cert
fi

#####################################################################################
# create self signed certificate
#####################################################################################
answersCreateKey() {
    echo --
    echo SomeState
    echo SomeCity
    echo SomeOrganization
    echo SomeOrganizationalUnit
    echo localhost.localdomain
    echo root@localhost.localdomain
}

if [ ! -f $key_directory/certs/$server_name.crt ]
then
    rm -Rf key
    mkdir key
    cd key

    # generate a private key, and self signed certificate
    answersCreateKey | openssl req -newkey rsa:2048 -keyout $server_name.key -nodes -x509 -days 365 -out $server_name.crt

    cp $server_name.key $key_directory/private
    cp $server_name.crt $key_directory/certs

    cat $key_directory/certs/$server_name.crt \
        $key_directory/private/$server_name.key \
        > $key_directory/certs/$server_name.bundle.pem

    if [ -f $key_directory/certs/$ca_subclass_file ]
    then
        # using a certificate signed by a CA
        cat $key_directory/certs/$ca_subclass_file \
            $key_directory/certs/$ca_file \
            >> $key_directory/certs/$server_name.bundle.pem
        cat $key_directory/certs/$ca_file \
            $key_directory/certs/$ca_subclass_file \
            > $key_directory/certs/$server_name.ca-chain.pem
    else
        # we do not have a ca for the self signed certificate, so using our own certificate
        cat $key_directory/certs/$server_name.crt > $key_directory/certs/$server_name.ca-chain.pem
    fi

    cd ..

    groupadd $sslgroup
    chmod -R 640 $key_directory/private/*
    chmod -R 640 $key_directory/certs/*
    chown -R root:$sslgroup $key_directory/*

    # cat $key_directory/certs/$ca_file >> $key_directory/certs/ca-bundle.crt
fi

#####################################################################################
# configure Cyrus
#####################################################################################
usermod -G saslauth,$sslgroup cyrus
sed -r -i \
    -e "s|^tls_cert_file:.*|tls_cert_file: $key_directory/certs/$server_name.crt|g" \
    -e "s|^tls_key_file:.*|tls_key_file: $key_directory/private/$server_name.key|g" \
    -e "s|^tls_ca_file:.*|tls_ca_file: $key_directory/certs/$server_name.ca-chain.pem|g" \
    /etc/imapd.conf
echo "test\
test" | saslpasswd2 /etc/sasldb2
chown cyrus: /etc/sasldb2
chmod 640 /etc/sasldb2
service cyrus-imapd restart

#####################################################################################
# configure Postfix
#####################################################################################
usermod -G mail,$sslgroup postfix
postconf -e smtpd_tls_key_file=$key_directory/private/$server_name.key
postconf -e smtpd_tls_cert_file=$key_directory/certs/$server_name.crt
postconf -e smtpd_tls_CAfile=$key_directory/certs/$server_name.ca-chain.pem
service postfix restart

#####################################################################################
# configure Apache mod_ssl
#####################################################################################
# for CentOS:
if [ -d /etc/httpd ]
then
    yum -y install mod_ssl

    if [ -f /etc/httpd/conf.d/nss.conf ]
    then
      # deactivate mod_nss
      mv /etc/httpd/conf.d/nss.conf /etc/httpd/conf.d/nss.conf.disabled
    fi

    sed -i -e "s#^SSLCertificateKeyFile.*#SSLCertificateKeyFile $key_directory/private/$server_name.key#" /etc/httpd/conf.d/ssl.conf
    sed -i -e "s#^SSLCertificateFile.*#SSLCertificateFile $key_directory/certs/$server_name.crt#" /etc/httpd/conf.d/ssl.conf
    sed -i -e "s/^#SSLCACertificateFile/SSLCACertificateFile/" /etc/httpd/conf.d/ssl.conf
    sed -i -e "s#^SSLCACertificateFile.*#SSLCACertificateFile $key_directory/certs/$server_name.ca-chain.pem#" /etc/httpd/conf.d/ssl.conf

    # fix fully qualified hostname for httpd
    hostname=`hostname`
    sed -i -e "s/^#ServerName/ServerName/" /etc/httpd/conf/httpd.conf
    sed -i -e "s#^ServerName.*#ServerName $hostname:443#" /etc/httpd/conf/httpd.conf

    if [[ "`cat /etc/httpd/conf/httpd.conf | grep "VirtualHost _default_:80"`" == "" ]]
    then
      echo '

      <VirtualHost _default_:80>
            RewriteEngine On
            RewriteRule ^(.*)$ https://%{HTTP_HOST}$1 [R=301,L]
      </VirtualHost>
      ' >> /etc/httpd/conf/httpd.conf
    fi

    if [[ "`cat /etc/httpd/conf.d/ssl.conf | grep "roundcubemail"`" == "" ]]
    then
      sed -i -e 's/<\/VirtualHost>/\tRedirectMatch ^\/$ \/roundcubemail\/\n<\/VirtualHost>/' /etc/httpd/conf.d/ssl.conf
    fi

    service httpd restart
# for Debian
else
    #certutil -d /etc/apache2/alias -A  -t "CT,," -n "StartCom Certification Authority" -i $key_directory/private/$ca_file
    pwd=foo
    openssl pkcs12 -export -in $key_directory/certs/$server_name.crt -inkey $key_directory/private/$server_name.key -out /tmp/$server_name.p12 -name Server-Cert -passout pass:$pwd
    echo "$pwd" > /tmp/foo
    pk12util -i /tmp/$server_name.p12 -d /etc/apache2/alias -w /tmp/foo -k /dev/null
    rm /tmp/foo
    rm /tmp/$server_name.p12

    sed -i -e 's/8443/443/' /etc/apache2/conf.d/nss.conf
    sed -i -e 's/NSSNickname.*/NSSNickname Server-Cert/' /etc/apache2/conf.d/nss.conf

    echo '

    <VirtualHost _default_:80>
            RewriteEngine On
            RewriteRule ^(.*)$ https://%{HTTP_HOST}$1 [R=301,L]
    </VirtualHost>
    ' >> /etc/apache2/conf/httpd.conf

    sed -i -e 's/<\/VirtualHost>/\tRedirectMatch ^\/$ \/roundcubemail\/\n<\/VirtualHost>/' /etc/apache2/conf.d/nss.conf

    service apache2 restart
fi

#####################################################################################
# configure Kolab backend
#####################################################################################
sed -r -i \
    -e '/api_url/d' \
    -e "s#\[kolab_wap\]#[kolab_wap]\napi_url = https://localhost/kolab-webadmin/api#g" \
    /etc/kolab/kolab.conf

#####################################################################################
# configure Kolab webclient
#####################################################################################
replace="s#\?>#\$config['kolab_http_request']=array(\n'ssl_verify_peer'=>true,\n'ssl_verify_host'=>true,\n'ssl_cafile'=>'$key_directory/certs/ca-bundle.crt'\n);\n?>#g"

sed -r -i -e $replace /etc/roundcubemail/config.inc.php

if [ ! -f $key_directory/private/$ca_subclass_file ]
then
    sed -r -i -e "s/'ssl_verify_peer'=>true/'ssl_verify_peer'=>false/g" /etc/roundcubemail/config.inc.php
fi

sed -i -e 's/http:/https:/' /etc/roundcubemail/kolab_files.inc.php

#####################################################################################
# configure LDAP server
#####################################################################################
# not done here, no need to access it from the outside.
# the firewall should block port 389
