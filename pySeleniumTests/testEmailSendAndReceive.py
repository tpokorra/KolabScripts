#!/usr/bin/env python

import unittest
import time
import datetime
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from helperKolabWAP import KolabWAPTestHelpers

# assumes password for cn=Directory Manager is test
# will create 2 new user, and send an email via roundcube from one user to the other
# will login to roundcube and check for the new email
class KolabEmailSendAndReceiveEmail(unittest.TestCase):

    def setUp(self):
        self.kolabWAPhelper = KolabWAPTestHelpers()
        self.driver = self.kolabWAPhelper.init_driver()

    def test_send_and_receive_email(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_send_and_receive_email")
        
        # login Directory Manager, create 2 users
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")
        username1, emailLogin1, password1, uid1 = kolabWAPhelper.create_user()
        username2, emailLogin2, password2, uid2 = kolabWAPhelper.create_user()
        kolabWAPhelper.logout_kolab_wap()

        # login user1 to roundcube and send email
        kolabWAPhelper.login_roundcube("/roundcubemail", emailLogin1, password1)
        emailSubjectLine = kolabWAPhelper.send_email(emailLogin2)
        kolabWAPhelper.logout_roundcube()

        # login user2 to roundcube and check for email
        kolabWAPhelper.login_roundcube("/roundcubemail", emailLogin2, password2)
        kolabWAPhelper.check_email_received(emailSubjectLine=emailSubjectLine)
        kolabWAPhelper.logout_roundcube()

    def tearDown(self):
        self.kolabWAPhelper.tear_down()

if __name__ == "__main__":
    unittest.main()


