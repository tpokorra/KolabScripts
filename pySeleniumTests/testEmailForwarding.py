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
        kolabWAPhelper.check_email_received(emailSubjectLine=subject)
        kolabWAPhelper.logout_roundcube()

    def test_mail_forwarding_external(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_mail_forwarding_external")

        # login Directory Manager, create a user
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        # please modify following line to add a domain that actually can receive emails, ie. has a valid MX record
        enabled_maildomain="soliderp.net"
        # quit the test if that domain does not exist in the current setup
        kolabWAPhelper.select_domain(enabled_maildomain);

        # add the user
        username, emailLogin, password = kolabWAPhelper.create_user()

        # create a forward address
        # using an external echo address (see https://de.wikipedia.org/wiki/Echo-Mailer)
        username2, emailForwardAddress, password2 = kolabWAPhelper.create_user(forward_to="echo@tu-berlin.de")

        kolabWAPhelper.logout_kolab_wap()

        # login user to roundcube and check for email
        kolabWAPhelper.login_roundcube("/roundcubemail", emailLogin, password)
        print "sending email to " + emailForwardAddress
        emailSubjectLine = kolabWAPhelper.send_email(emailForwardAddress)
        kolabWAPhelper.wait_loading(5.0)
        kolabWAPhelper.check_email_received(emailSubjectLine="Re: " + emailSubjectLine)
        kolabWAPhelper.logout_roundcube()

    def tearDown(self):
        
        # write current page for debugging purposes
        self.kolabWAPhelper.log_current_page()
        
        self.driver.quit()

if __name__ == "__main__":
    unittest.main()


