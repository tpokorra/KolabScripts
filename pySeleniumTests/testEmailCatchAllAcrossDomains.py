#!/usr/bin/env python

import unittest
import time
import datetime
import string
import subprocess
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from helperKolabWAP import KolabWAPTestHelpers

# assumes password for cn=Directory Manager is test
# will create 1 new domain, with a user
# will setup a catch all address for another domain as alias (checking if domain is in /etc/postfix/virtual_alias_maps_manual.cf)
# will send email from command line
# will login to roundcube and check for the new email
class KolabEmailCatchAllAcrossDomains(unittest.TestCase):

    def setUp(self):
        self.kolabWAPhelper = KolabWAPTestHelpers()
        self.driver = self.kolabWAPhelper.init_driver()

    def test_catch_all_across_domains(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_catch_all_across_domains")
        
        # login Directory Manager, create a domain and a user
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")
        # important: alias domain must be set in the domain names, otherwise: email address not in local domain
        domainname = kolabWAPhelper.create_domain(withAliasDomain=True)
        aliasdomainname = string.replace(domainname, "domain", "alias")

        username = "user" + datetime.datetime.now().strftime("%Y%m%d%H%M%S")
        # what happens if we have not added the alias domain yet to postfix config?
        kolabWAPhelper.create_user(
            username=username,
            alias="catchall@" + aliasdomainname,
            expected_message_contains="Alias 'catchall@" + aliasdomainname +"' must be configured manually")

        # add alias domain, and call postmap
        postfixfile="/etc/postfix/virtual_alias_maps_manual.cf"
        subprocess.call(['/bin/bash', '-c', 'echo "catchall@' + aliasdomainname + ' ' + username + '.' + username +'@' + domainname + '" >> ' + postfixfile])
        subprocess.call(['postmap', postfixfile])
        subprocess.call(['service', 'postfix', 'restart'])
        
        # now add user for real
        username, emailLogin, password = kolabWAPhelper.create_user(username=username, alias="catchall@" + aliasdomainname)
        kolabWAPhelper.logout_kolab_wap()

        # send email to catch all alias address from command line
        print "sending email..."
        subprocess.call(['/bin/bash', '-c', 'echo "test" | mail -s "subject ' + aliasdomainname + '" test@' + aliasdomainname])
        kolabWAPhelper.wait_loading(2.0)

        # login user to roundcube and check for email
        kolabWAPhelper.login_roundcube("/roundcubemail", emailLogin, password)
        kolabWAPhelper.check_email_received("subject " + aliasdomainname)
        kolabWAPhelper.logout_roundcube()

    def tearDown(self):
        
        # write current page for debugging purposes
        self.kolabWAPhelper.log_current_page()
        
        self.driver.close()

if __name__ == "__main__":
    unittest.main()


