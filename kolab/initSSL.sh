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
export ca_directory=/etc/pki/CA
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
    # we need a CA for dirsrv
    if [ ! -f $ca_directory/my-ca.crt ]
    then
      touch $ca_directory/index.txt
      echo 01 > $ca_directory/serial
      # generate a key without a passphrase, not encrypted
      openssl genrsa -out $ca_directory/private/my-ca.key 2048
      # generate the certificate for the CA
      subj="/C=XX/ST=empty/L=empty/O=My CA/OU=empty/CN=myca.net/emailAddress=dev@myca.net"
      openssl req -new -x509 -key $ca_directory/private/my-ca.key -days 3650 -subj "$subj" > $ca_directory/my-ca.crt
    fi

    rm -Rf keys
    mkdir keys
    cd keys

    # generate a private key, and self signed certificate
    writeConf
    # generate a key without a passphrase, not encrypted
    openssl genrsa -out $server_name.key 2048
    # generate a CSR
    openssl req -new -key $server_name.key -out $server_name.csr -config req.conf -extensions 'v3_req'
    # generate the certificate
    openssl x509 -req -in $server_name.csr -CA /etc/pki/CA/my-ca.crt -CAkey /etc/pki/CA/private/my-ca.key -CAcreateserial -out $server_name.crt -days 1024 -sha256

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
      if [ -f $ca_directory/my-ca.crt ]
      then
        cat /etc/pki/CA/my-ca.crt > $key_directory/certs/$server_name.bundle.pem
        cat /etc/pki/CA/my-ca.crt > $key_directory/certs/$server_name.ca-chain.pem
      else
        # we do not have a ca for the self signed certificate, so using our own certificate
        cat $key_directory/certs/$server_name.crt > $key_directory/certs/$server_name.ca-chain.pem
      fi
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
    -e "s|^tls_server_key:.*|tls_server_key: $key_directory/private/$server_name.key\ntls_client_ca_file: $key_directory/certs/$server_name.ca-chain.pem|g" \
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
    if [[ $OS == Ubuntu* ]]
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
export slapdir=$(find /etc/dirsrv -type d -name slapd-*)
export slapdir=$(basename $slapdir)
servercert="Server-Cert"
certutil -A -d /etc/dirsrv/$slapdir/ -n "ca_cert" -t "TCu,TCu,TCu" -i $key_directory/certs/$server_name.ca-chain.pem 
certutil -A -d /etc/dirsrv/$slapdir/ -n "$servercert" -t "TCu,TCu,TCu" -i $key_directory/certs/$server_name.bundle.pem

echo "Internal (Software) Token:foo" > /etc/dirsrv/$slapdir/pin.txt

openssl pkcs12 -export \
    -in $key_directory/certs/$server_name.crt \
    -inkey $key_directory/private/$server_name.key \
    -out /tmp/example.p12 -name "$servercert" -passout pass:foo
echo "foo" > /tmp/foo
pk12util -i /tmp/example.p12 -d /etc/dirsrv/$slapdir/ \
    -w /tmp/foo -k /dev/null
rm -f /tmp/foo
rm -f /tmp/example.p12

certutil -M -n "ca_cert" -t TCu,TCu,TCu -d /etc/dirsrv/$slapdir/
certutil -M -n "$servercert" -t TCu,TCu,TCu -d /etc/dirsrv/$slapdir/
# to test:
#certutil -L -d /etc/dirsrv/$slapdir/
#certutil -V -d /etc/dirsrv/$slapdir/ -n "ca_cert" -eu CVS
#certutil -V -d /etc/dirsrv/$slapdir/ -n "$servercert" -eu CVS

echo "Internal (Software) Token:foo" > /etc/dirsrv/$slapdir/pin.txt

passwd=$(grep ^bind_pw /etc/kolab/kolab.conf | cut -d '=' -f2- | sed -e 's/\s*//g')
ldapmodify -x -h localhost -p 389 \
    -D "cn=Directory Manager" -w "${passwd}" << EOF
dn: cn=encryption,cn=config
changetype: modify
replace: nsSSL2
nsSSL2: off
-
replace: nsSSL3
nsSSL3: off
-
replace: nsTLS1
nsTLS1: on
-
replace: nsSSLClientAuth
nsSSLClientAuth: allowed

dn: cn=config
changetype: modify
add: nsslapd-security
nsslapd-security: on
-
replace: nsslapd-ssl-check-hostname
nsslapd-ssl-check-hostname: off
-
replace: nsslapd-secureport
nsslapd-secureport: 636

dn: cn=RSA,cn=encryption,cn=config
changetype: add
objectclass: top
objectclass: nsEncryptionModule
cn: RSA
nsSSLPersonalitySSL: $servercert
nsSSLToken: internal (software)
nsSSLActivation: on
EOF

systemctl restart dirsrv.target

# to test: openssl s_client -connect localhost:636 -CAfile /etc/pki/CA/my-ca.crt
# for ldapsearch, you need to install /etc/pki/CA/my-ca.crt to your clients ldap configuration
# to test: ldapsearch -x -H ldap://localhost  -Z    -b "cn=kolab,cn=config" -D "cn=Directory Manager"     -w "${passwd}"
# to test: ldapsearch -x -H ldaps://localhost       -b "cn=kolab,cn=config" -D "cn=Directory Manager"     -w "${passwd}"
