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
# will create a new user
# will create a new mail forwarding account, to the email of the created user
# will send email from command line
# will login to roundcube and check for the new email
class KolabEmailMailForwarding(unittest.TestCase):

    def setUp(self):
        self.kolabWAPhelper = KolabWAPTestHelpers()
        self.driver = self.kolabWAPhelper.init_driver()

    def test_mail_forwarding(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_mail_forwarding")
        
        # login Directory Manager, create a user
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        # add the user
        username, emailLogin, password = kolabWAPhelper.create_user()
        
        # create a forward address
        username2, emailForwardAddress, password2 = kolabWAPhelper.create_user(forward_to=emailLogin)
        
        kolabWAPhelper.logout_kolab_wap()

        # send email to the forward address from command line
        print "sending email to " + emailForwardAddress
        subject = 'for ' + username
        subprocess.call(['/bin/bash', '-c', 'echo "test" | mail -s "' + subject + '" ' + emailForwardAddress])
        kolabWAPhelper.wait_loading(2.0)

        # login user to roundcube and check for email
        kolabWAPhelper.login_roundcube("/roundcubemail", emailLogin, password)
        kolabWAPhelper.check_email_received(subject)
        kolabWAPhelper.logout_roundcube()

    def tearDown(self):
        
        # write current page for debugging purposes
        self.kolabWAPhelper.log_current_page()
        
        self.driver.close()

if __name__ == "__main__":
    unittest.main()


