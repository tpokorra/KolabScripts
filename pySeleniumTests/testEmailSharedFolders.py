#!/usr/bin/env python

import unittest2 as unittest
import time
import datetime
import subprocess
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from helperKolabWAP import KolabWAPTestHelpers

# assumes password for cn=Directory Manager is test
# will create a shared folder and 2 new users, 
# and send an email to the shared folder.
# will login to roundcube and check for the new email
class KolabEmailSharedFolders(unittest.TestCase):

    def setUp(self):
        unittest.TestCase.__init__(self, '__init__')
        self.kolabWAPhelper = KolabWAPTestHelpers()
        self.driver = self.kolabWAPhelper.init_driver()

    def test_shared_folder(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_shared_folder")
        
        # login Directory Manager, create 2 users
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")
        username1, emailLogin1, password1 = kolabWAPhelper.create_user()
        #username2, emailLogin2, password2 = kolabWAPhelper.create_user()

        # create shared folder
        # could use delegates=[emailLogin1, emailLogin2], but this is not tested at the moment
        emailSharedFolder, foldername = kolabWAPhelper.create_shared_folder()
        kolabWAPhelper.logout_kolab_wap()
        
        # need to give everyone permission to send to this folder
        # need to wait some seconds, otherwise the permissions will be reset to lrs, probably by kolabd???
        kolabWAPhelper.wait_loading(20.0)
        subprocess.call(['/bin/bash', '-c', "kolab sam shared/" + emailSharedFolder + " anyone lrsp"])
        kolabWAPhelper.wait_loading(20.0)
        subprocess.call(['/bin/bash', '-c', "kolab lam shared/" + emailSharedFolder])

        # login user to roundcube to send and check for email
        kolabWAPhelper.login_roundcube("/roundcubemail", emailLogin1, password1)
        
        # TODO: why can I see and subscribe to all folders in the domain?
        # can we set permissions who can read the folder? Recipient Access list?
        # solution: http://lists.kolab.org/pipermail/users/2013-December/016161.html
        #           quote: Shared folders are created with the ACL "anyone lrs" (anyone read) per default.  
        #                  After creating them you'll likely adjust the ACLs based on your needs.
        
        print "sending email to " + emailSharedFolder
        emailSubjectLine = kolabWAPhelper.send_email(emailSharedFolder)
        kolabWAPhelper.wait_loading(3.0)
        kolabWAPhelper.check_email_received(emailSubjectLineDoesNotContain="Undelivered Mail Returned to Sender")
        # no need to subscribe the folder, because we are using the direct url to load the folder in Roundcube
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


