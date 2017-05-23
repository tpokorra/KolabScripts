#!/bin/bash

if [ -z $1 ]
then
  echo "Please call: $0 <url of server>"
  echo "  eg. $0 example.org"
  exit 1
fi
export server_name=$1

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

DetermineOS
InstallWgetAndPatch
DeterminePythonPath

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
    key_directory=/etc/ssl
    sslgroup=ssl-cert
fi

#####################################################################################
# create self signed certificate
#####################################################################################
writeConf() {
cat > req.conf <<FINISH
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no
[req_distinguished_name]
C = DE
ST = SomeState
L = SomeCity
O = SomeOrganization
OU = SomeOrganizationalUnit
CN = $server_name
[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = $server_name
DNS.2 = localhost
FINISH

}

if [ ! -f $key_directory/certs/$server_name.crt ]
then
    rm -Rf keys
    mkdir keys
    cd keys

    # generate a private key, and self signed certificate
    writeConf
    openssl req -newkey rsa:2048 -keyout $server_name.key -nodes -x509 -days 365 -out $server_name.crt -config req.conf

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
    -e "s|^tls_server_cert:.*|tls_server_cert: $key_directory/certs/$server_name.crt|g" \
    -e "s|^tls_server_key:.*|tls_server_key: $key_directory/private/$server_name.key|g" \
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
# for CentOS and Fedora
if [[ $OS == CentOS* || $OS == Fedora* ]]
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
      newConfigLines="\tRewriteEngine On\n \
\tRewriteRule ^/roundcubemail/[a-f0-9]{16}/(.*) /roundcubemail/\$1 [PT,L]\n \
\tRewriteRule ^/webmail/[a-f0-9]{16}/(.*) /webmail/\$1 [PT,L]\n \
\tRedirectMatch ^/$ /roundcubemail/\n"

      sed -i -e "s#</VirtualHost>#$newConfigLines</VirtualHost>#" /etc/httpd/conf.d/ssl.conf

      newConfigLines="\t\n \
\t# Be compatible with older packages and installed plugins.\n \
\tRewriteCond %{REQUEST_URI} ^/roundcubemail/assets/\n \
\tRewriteCond %{REQUEST_URI} \!-f\n \
\tRewriteCond %{REQUEST_URI} \!-d\n \n"
#   \tRewriteRule .*/roundcubemail/assets/(.*)\$ /roundcubemail/\$1 [PT,L]\n"

#      sed -i -e "s~</VirtualHost>~$newConfigLines</VirtualHost>~" /etc/httpd/conf.d/ssl.conf
    fi

    service httpd restart

    # make sure that kolab list-domains works for Fedora 22 with a self signed certificate
    # error: ssl.SSLError: [SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed (_ssl.c:581)
    # see also https://www.python.org/dev/peps/pep-0476/
    # only fix this in Fedora 22 and higher
    if [[ $OS == Fedora* && $RELEASE -ge 22 ]]
    then
      patch -p1 -i `pwd`/patches/fixSelfSignedCertPykolab.patch -d $pythonDistPackages || exit -1
    fi
# for Debian and Ubuntu
elif [[ $OS == Ubuntu* || $OS == Debian* ]]
then
    a2dismod nss
    a2enmod ssl

    sed -i -e "s/NameVirtualHost \*:80/NameVirtualHost *:443/g" /etc/apache2/ports.conf

    defaultFile=/etc/apache2/sites-enabled/000-default
    if [ -f /etc/apache2/sites-enabled/000-default.conf ]
    then
      defaultFile=/etc/apache2/sites-enabled/000-default.conf
    fi

    sed -i -e "s/VirtualHost \*:80/VirtualHost \*:443/g" $defaultFile

    sed -i -e "s/^SSL/#SSL/g" $defaultFile
    newConfigLines="SSLEngine On\n\
SSLCertificateKeyFile $key_directory/private/$server_name.key\n\
SSLCertificateFile $key_directory/certs/$server_name.crt\n\
SSLCACertificateFile $key_directory/certs/$server_name.ca-chain.pem\n"

    sed -i -e "s#</VirtualHost>#$newConfigLines</VirtualHost>#" $defaultFile

    if [[ "`cat $defaultFile | grep "RewriteEngine On"`" == "" ]]
    then
      newConfigLines="\tRewriteEngine On\n \
\tRewriteRule ^/roundcubemail/[a-f0-9]{16}/(.*) /roundcubemail/\$1 [PT,L]\n \
\tRewriteRule ^/webmail/[a-f0-9]{16}/(.*) /webmail/\$1 [PT,L]\n \
\tRedirectMatch ^/$ /roundcubemail/\n"

      sed -i -e "s#</VirtualHost>#$newConfigLines</VirtualHost>#" $defaultFile
    fi
    service apache2 restart

    # make sure that kolab list-domains works for Debian Jessie with a self signed certificate
    # error: ssl.SSLError: [SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed (_ssl.c:581)
    # see also https://www.python.org/dev/peps/pep-0476/
    # only fix this in Debian Jessie, in Debian Wheezy there is no such method: AttributeError: 'module' object has no attribute '_create_unverified_context'
    if [[ $OS == Debian* && $RELEASE -ge 8 ]]
    then
      patch -p1 -i `pwd`/patches/fixSelfSignedCertPykolab.patch -d $pythonDistPackages || exit -1
    fi
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
sed -i -e 's/http:/https:/' /etc/roundcubemail/kolab_addressbook.inc.php
sed -i -e 's/http:/https:/' /etc/roundcubemail/calendar.inc.php
sed -i -e 's/http:/https:/' /etc/roundcubemail/config.inc.php

#####################################################################################
# configure LDAP server
#####################################################################################
# not done here, no need to access it from the outside.
# the firewall should block port 389
