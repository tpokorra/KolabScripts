#!/usr/bin/env python

import unittest
import time
import datetime
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from helperKolabWAP import KolabWAPTestHelpers

# assumes password for cn=Directory Manager is test
# will create a shared folder and 2 new users, 
# and send an email to the shared folder.
# will login to roundcube and check for the new email
class KolabEmailSharedFolders(unittest.TestCase):

    def setUp(self):
        self.kolabWAPhelper = KolabWAPTestHelpers()
        self.driver = self.kolabWAPhelper.init_driver()

    def test_shared_folder(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_send_and_receive_email")
        
        # login Directory Manager, create 2 users
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")
        username1, emailLogin1, password1 = kolabWAPhelper.create_user()
        username2, emailLogin2, password2 = kolabWAPhelper.create_user()

        # create shared folder
        emailSharedFolder, foldername = kolabWAPhelper.create_shared_folder(delegates=[emailLogin1, emailLogin2])
        kolabWAPhelper.logout_kolab_wap()

        # login user to roundcube to send and check for email
        kolabWAPhelper.login_roundcube("/roundcubemail", emailLogin1, password1)
        
        # TODO: need to subscribe the folder
        # Question: why can I see and subscribe to all folders in the domain? even when the user is not in the delegates list?
        
        print "sending email to " + emailSharedFolder
        emailSubjectLine = kolabWAPhelper.send_email(emailSharedFolder)
        kolabWAPhelper.wait_loading(3.0)
        kolabWAPhelper.check_email_received(emailSubjectLineDoesNotContain="Undelivered Mail Returned to Sender")
        kolabWAPhelper.check_email_received(
                        folder="Shared+Folders%2Fshared%2F"+foldername, 
                        emailSubjectLine=emailSubjectLine)
        kolabWAPhelper.logout_roundcube()

    def tearDown(self):
        
        # write current page for debugging purposes
        self.kolabWAPhelper.log_current_page()
        
        self.driver.close()

if __name__ == "__main__":
    unittest.main()


