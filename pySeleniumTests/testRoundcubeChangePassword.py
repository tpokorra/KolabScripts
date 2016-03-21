#!/usr/bin/env python

import unittest
import time
import datetime
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import NoSuchElementException
from helperKolabWAP import KolabWAPTestHelpers

# assumes password for cn=Directory Manager is test
# will create a new user, and try to login in Roundcube and try to change the password
class KolabRoundcubeChangePassword(unittest.TestCase):

    def setUp(self):
        self.kolabWAPhelper = KolabWAPTestHelpers()
        self.driver = self.kolabWAPhelper.init_driver()

    def helper_user_change_password(self, oldpassword):
        driver = self.driver

        url = driver.current_url[:driver.current_url.find("?")]
        driver.get(url + "?_task=settings&_action=plugin.password")
        self.kolabWAPhelper.wait_loading(0.5)

        elem = driver.find_element_by_id("curpasswd")
        elem.send_keys(oldpassword)
        elem = driver.find_element_by_id("newpasswd")
        elem.send_keys(oldpassword+"new")
        elem = driver.find_element_by_id("confpasswd")
        elem.send_keys(oldpassword+"new")

        elem = driver.find_element_by_xpath("//form[@id=\"password-form\"]//input[@class=\"button mainaction\"]")
        elem.click()

        self.kolabWAPhelper.wait_loading()
        try:
            elem = driver.find_element_by_class_name("error")
            self.assertEquals("", elem.text, "User password was not changed: " + elem.text)            
        except NoSuchElementException, e:
            # no problem, usually there should not be an error
            elem = driver.find_element_by_class_name("confirmation")
            self.assertEquals("Successfully saved.", elem.text, "User password should have been successfully saved, but was: " + elem.text)
        
        self.kolabWAPhelper.log("User has updated his password successfully")


    def test_edit_user_password(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_edit_user_password")
        
        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        username, emailLogin, password, uid = kolabWAPhelper.create_user()

        kolabWAPhelper.logout_kolab_wap()

        # login the new user
        kolabWAPhelper.login_roundcube("/roundcubemail", emailLogin, password)
        self.helper_user_change_password(password)
        kolabWAPhelper.logout_roundcube()

    def test_edit_user_password_multi_domain(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_edit_user_password_multi_domain")
        
        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        domainname = kolabWAPhelper.create_domain()

        username, emailLogin, password, uid = kolabWAPhelper.create_user()

        kolabWAPhelper.logout_kolab_wap()

        # login the new user
        kolabWAPhelper.login_roundcube("/roundcubemail", emailLogin, password)
        self.helper_user_change_password(password)
        kolabWAPhelper.logout_roundcube()

    def tearDown(self):
        
        # write current page for debugging purposes
        self.kolabWAPhelper.log_current_page()
        
        self.driver.quit()

if __name__ == "__main__":
    unittest.main()


