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
# will change the mailhost attribute of Kolab User to default to localhost
# this helps with the tests, because we don't need to wait for kolabd to write mailhost
# see https://github.com/TBits/KolabScripts/issues/73
class KolabUserMailhostLocalhost(unittest.TestCase):

    def setUp(self):
        self.kolabWAPhelper = KolabWAPTestHelpers()
        self.driver = self.kolabWAPhelper.init_driver()

    def modify_mailhost_default(self):
        driver = self.driver
        driver.get(driver.current_url)

        elem = driver.find_element_by_link_text("Settings")
        elem.click()
        self.kolabWAPhelper.wait_loading()
        elem = self.driver.find_element_by_id("searchinput")
        elem.send_keys("Kolab User")
        elem.send_keys(Keys.ENTER)
        self.kolabWAPhelper.wait_loading(initialwait = 2)
        elem = self.driver.find_element_by_xpath("//table[@id='settingstypelist']/tbody/tr/td")
        self.assertEquals("Kolab User", elem.text, "Expected to select Kolab User but was " + elem.text)
        elem.click()
        self.kolabWAPhelper.wait_loading(initialwait = 1)
        elem = driver.find_element_by_link_text("Attributes")
        elem.click()
        elem = driver.find_element_by_xpath("//tr[@id='attr_table_row_mailhost']/td[@class='actions']/a[@href='#edit']").click()
        self.kolabWAPhelper.wait_loading(0.5)
        driver.find_element_by_xpath("//tr[@id='attr_form_row_value']/td[@class='value']/select/option[@value='normal']").click()
        elem = driver.find_element_by_xpath("//tr[@id='attr_form_row_default']/td[@class='value']/input")
        elem.send_keys("localhost")
        driver.find_element_by_xpath("//input[@value='Save']").click()
        
        elem = driver.find_element_by_xpath("//input[@value=\"Submit\"]").click()
        self.kolabWAPhelper.wait_loading()
        elem = driver.find_element_by_xpath("//div[@id=\"message\"]")
        self.assertEquals("Object type updated successfully.", elem.text, "object type was not updated successfully, message: " + elem.text)

    def test_modify_mailhost_default(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_modify_mailhost_default")
        
        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        self.modify_mailhost_default()

        kolabWAPhelper.logout_kolab_wap()

    def tearDown(self):
        
        # write current page for debugging purposes
        self.kolabWAPhelper.log_current_page()
        
        self.driver.quit()

if __name__ == "__main__":
    unittest.main()


