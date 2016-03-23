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
# will check that it is not possible to create a user with the same uid in another domain
# will authenticate with kolab-saslauthd with just the uid
# will login to webadmin with just the uid
class KolabUniqueIDAcrossDomains(unittest.TestCase):

    def setUp(self):
        self.kolabWAPhelper = KolabWAPTestHelpers()
        self.driver = self.kolabWAPhelper.init_driver()

    def enable_editable_uid(self):
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
        elem = driver.find_element_by_xpath("//tr[@id='attr_table_row_uid']/td[@class='actions']/a[@href='#edit']").click()
        self.kolabWAPhelper.wait_loading(0.5)
        driver.find_element_by_xpath("//tr[@id='attr_form_row_value']/td[@class='value']/select/option[@value='auto']").click()
        driver.find_element_by_xpath("//input[@value='Save']").click()
        
        elem = driver.find_element_by_xpath("//input[@value=\"Submit\"]").click()
        self.kolabWAPhelper.wait_loading()
        elem = driver.find_element_by_xpath("//div[@id=\"message\"]")
        self.assertEquals("Object type updated successfully.", elem.text, "object type was not updated successfully, message: " + elem.text)

    def test_unique_id_across_domains(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_unique_id_across_domains")
        
        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        # create a user in the primary domain
        username = "user" + datetime.datetime.now().strftime("%Y%m%d%H%M%S") + "uid"
        self.enable_editable_uid()
        username, emailLogin, password, uid = kolabWAPhelper.create_user(username=username, uid=username)

        # create a domain and select it
        domainname = kolabWAPhelper.create_domain()

        # attempt to create a user with the same username as in the primary domain, should result in a uid with digit 2 attached
        username, emailLogin, password, uid = kolabWAPhelper.create_user(username=username)
        self.assertEquals(username + "2", uid, "generate_uid should create a unique id across domains for same surname, expected " + username + "2, but got: " + uid)

        # attempt to create a user with the same uid as in the primary domain
        kolabWAPhelper.create_user(username=username, uid=username, expected_message_contains=("Error: The unique identity (UID) " + username + " is already in use."))

        # create a new user
        username = "user" + datetime.datetime.now().strftime("%Y%m%d%H%M%S")
        username, emailLogin, password, uid = kolabWAPhelper.create_user(username=username)
        kolabWAPhelper.logout_kolab_wap()

        # test kolab-saslauthd from the commandline
        print("testsaslauthd with " + emailLogin)
        p = subprocess.Popen("/usr/sbin/testsaslauthd -u " + emailLogin + " -p '" + password + "'", shell=True, stdout=subprocess.PIPE)
        out, err = p.communicate()
        self.assertTrue('0: OK "Success."' in out, "login did not work, it shows " + out)
        
        print("testsaslauthd with " + username)
        p = subprocess.Popen("/usr/sbin/testsaslauthd -u " + username + " -p '" + password + "'", shell=True, stdout=subprocess.PIPE)
        out, err = p.communicate()
        self.assertTrue('0: OK "Success."' in out, "login did not work, it shows " + out)

        print("testsaslauthd with wrong password")
        p = subprocess.Popen("/usr/sbin/testsaslauthd -u " + username + " -p '" + password + "fail'", shell=True, stdout=subprocess.PIPE)
        out, err = p.communicate()
        self.assertTrue('0: NO "authentication failed"' in out, "login should not work with wrong password, but it shows " + out)

        # login user to kolab webadmin with wrong password should fail
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", username, password+"fail", "Incorrect username or password!")

        # login user to kolab webadmin with the email login
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", emailLogin, password)
        kolabWAPhelper.logout_kolab_wap()

        # login user to kolab webadmin with just the uid
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", username, password)
        kolabWAPhelper.logout_kolab_wap()

    def tearDown(self):
        
        # write current page for debugging purposes
        self.kolabWAPhelper.log_current_page()
        
        self.driver.quit()

if __name__ == "__main__":
    unittest.main()


