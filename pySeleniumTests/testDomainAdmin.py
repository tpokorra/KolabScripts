#!/usr/bin/env python

import unittest
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from helperKolabWAP import KolabWAPTestHelpers

# assumes password for cn=Directory Manager is test.
# assumes that the initTBitsISP.sh script has been run.
# will create a domain admin user in the domain administrators.org (type domainadmin)
# will create a new domain, and assign that domain admin user as domain administrator
# will create users inside that new domain (type normal kolab user)
class KolabWAPDomainAdmin(unittest.TestCase):

    def setUp(self):
        self.kolabWAPhelper = KolabWAPTestHelpers()
        self.driver = self.kolabWAPhelper.init_driver()

    # test if correct user type is used in a normal domain
    def test_default_user_type_in_normal_domain(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_default_user_type_in_normal_domain")
        
        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("http://localhost/kolab-webadmin", "cn=Directory Manager", "test")

        username, emailLogin, password = kolabWAPhelper.create_user(
            prefix = "user")

        # now edit the user
        elem = self.driver.find_element_by_id("searchinput")
        elem.send_keys(username)
        elem.send_keys(Keys.ENTER)
        kolabWAPhelper.wait_loading(initialwait = 2)

        elem = self.driver.find_element_by_xpath("//table[@id='userlist']/tbody/tr/td")
        self.assertEquals(username + ", " + username, elem.text, "Expected to select user " + username + " but was " + elem.text)
        elem.click()
        
        kolabWAPhelper.wait_loading()
        
        # check if the user type is actually a normal kolab user
        elem = self.driver.find_element_by_xpath("//form[@id='user-form']/fieldset/table/tbody/tr/td[@class='value']")
        self.assertEquals("Kolab User", elem.text, "user type should be Kolab User, but was " + elem.text)

        kolabWAPhelper.logout_kolab_wap()

    # test if correct user type is used when not many attributes are set which are specific for domain admins
    def test_domain_admin_user_type(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_domain_admin_user_type")

        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("http://localhost/kolab-webadmin", "cn=Directory Manager", "test")

        kolabWAPhelper.select_domain("administrators.org")

        username, emailLogin, password = kolabWAPhelper.create_user(
            prefix = "admin")

        # now edit the user
        elem = self.driver.find_element_by_id("searchinput")
        elem.send_keys(username)
        elem.send_keys(Keys.ENTER)
        kolabWAPhelper.wait_loading(initialwait = 2)

        elem = self.driver.find_element_by_xpath("//tbody/tr/td[@class=\"name\"]")
        self.assertEquals(username + ", " + username, elem.text, "Expected to select user " + username + " but was " + elem.text)
        elem.click()
        
        kolabWAPhelper.wait_loading()
        
        # check if the user type is actually a domain admin
        elem = self.driver.find_element_by_xpath("//form[@id='user-form']/fieldset/table/tbody/tr/td[@class='value']")
        self.assertEquals("Domain Administrator", elem.text, "user type should be Domain Administrator, but was " + elem.text)

        kolabWAPhelper.logout_kolab_wap()

    def tearDown(self):
        
        # write current page for debugging purposes
        self.kolabWAPhelper.log_current_page()
        
        self.driver.close()

if __name__ == "__main__":
    unittest.main()


