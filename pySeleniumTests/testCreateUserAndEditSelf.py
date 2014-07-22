#!/usr/bin/env python

import unittest
import time
import datetime
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from helperKolabWAP import KolabWAPTestHelpers

# assumes password for cn=Directory Manager is test
# will create a new user, and try to login is that user and change the initials
# will check kolab lm if the calendar folder has been created for the user
class KolabWAPCreateUserAndEditSelf(unittest.TestCase):

    def setUp(self):
        self.kolabWAPhelper = KolabWAPTestHelpers()
        self.driver = self.kolabWAPhelper.init_driver()

    # edit yourself; testing bug https://issues.kolab.org/show_bug.cgi?id=2414
    def helper_user_edits_himself(self):
        driver = self.driver
        elem = driver.find_element_by_xpath("//div[@class=\"settings\"]")
        elem.click()
        self.kolabWAPhelper.wait_loading()
        elem = driver.find_element_by_name("initials")
        elem.send_keys("T")
        elem = driver.find_element_by_xpath("//input[@value=\"Submit\"]")
        elem.click()
        self.kolabWAPhelper.wait_loading()
        elem = driver.find_element_by_xpath("//div[@id=\"message\"]")
        self.assertEquals("User updated successfully.", elem.text, "User was not saved successfully, message: " + elem.text)
        
        self.kolabWAPhelper.log("User has updated his own data successfully")


    def test_edit_user_himself(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_edit_user_himself")
        
        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        username, emailLogin, password = kolabWAPhelper.create_user()

        kolabWAPhelper.logout_kolab_wap()

        # login the new user
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", emailLogin, password)

        self.helper_user_edits_himself()
        
        kolabWAPhelper.logout_kolab_wap()

    def test_edit_user_himself_multi_domain_with_quota(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_edit_user_himself_multi_domain_with_quota")
        
        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        domainname = kolabWAPhelper.create_domain()

        username, emailLogin, password = kolabWAPhelper.create_user(mail_quota="20kb")

        kolabWAPhelper.logout_kolab_wap()

        # login the new user
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", emailLogin, password)

        self.helper_user_edits_himself()
        
        kolabWAPhelper.logout_kolab_wap()

    def test_edit_user_himself_multi_domain(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_edit_user_himself_multi_domain")
        
        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        domainname = kolabWAPhelper.create_domain()

        username, emailLogin, password = kolabWAPhelper.create_user()

        kolabWAPhelper.logout_kolab_wap()

        # login the new user
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", emailLogin, password)

        self.helper_user_edits_himself()
        
        kolabWAPhelper.logout_kolab_wap()


    def tearDown(self):
        
        # write current page for debugging purposes
        self.kolabWAPhelper.log_current_page()
        
        self.driver.close()

if __name__ == "__main__":
    unittest.main()


