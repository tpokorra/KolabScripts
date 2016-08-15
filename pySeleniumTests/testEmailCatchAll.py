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
# will setup a catch all address as alias
# will send email from command line
# will login to roundcube and check for the new email
class KolabEmailCatchAll(unittest.TestCase):

    def setUp(self):
        self.kolabWAPhelper = KolabWAPTestHelpers()
        self.driver = self.kolabWAPhelper.init_driver()

    def test_catch_all(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_catch_all")
        
        # login Directory Manager, create a domain and a user
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")
        domainname = kolabWAPhelper.create_domain()

        # add the user
        username, emailLogin, password, uid = kolabWAPhelper.create_user(alias="catchall@" + domainname)

        # add another user with an email address that should be excluded from catchall
        username2, emailLogin2, password2, uid2 = kolabWAPhelper.create_user()

        kolabWAPhelper.logout_kolab_wap()

        # send email to catch all alias address from command line
        print "sending email..."
        subject = 'subject ' + domainname
        subprocess.call(['/bin/bash', '-c', 'echo "test" | mail -s "' + subject + '" alias' + domainname + '@' + domainname])

        # send email to the other user from the command line
        subject2 = 'subject ' + username2
        subprocess.call(['/bin/bash', '-c', 'echo "test" | mail -s "' + subject2 + '" ' + emailLogin2])
 
        kolabWAPhelper.wait_loading(2.0)

        # login catchall user to roundcube and check for email
        kolabWAPhelper.login_roundcube("/roundcubemail", emailLogin, password)
        kolabWAPhelper.check_email_received(emailSubjectLine=subject)
        kolabWAPhelper.logout_roundcube()

        # login other user to roundcube and check for email
        kolabWAPhelper.login_roundcube("/roundcubemail", emailLogin2, password2)
        kolabWAPhelper.check_email_received(emailSubjectLine=subject2)
        kolabWAPhelper.logout_roundcube()

    def tearDown(self):
        self.kolabWAPhelper.tear_down()

if __name__ == "__main__":
    unittest.main()


