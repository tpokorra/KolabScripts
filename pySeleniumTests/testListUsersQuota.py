#!/usr/bin/env python

import unittest
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from helperKolabWAP import KolabWAPTestHelpers

# assumes password for cn=Directory Manager is test.
# assumes that the initTBitsISP.sh script has been run.
# will create a new domain admin, a normal user without kolab-admin role, and a user with kolab-admin role.
# will check if those users can see the report
class KolabWAPListQuotaReport(unittest.TestCase):

    def setUp(self):
        self.kolabWAPhelper = KolabWAPTestHelpers()
        self.driver = self.kolabWAPhelper.init_driver()

    # test that unprivileged user cannot see the report
    def test_unprivileged_user(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_unprivileged_user")
        driver = self.driver
        
        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        username, emailLogin, password, uid = kolabWAPhelper.create_user(
            prefix = "user")

        kolabWAPhelper.logout_kolab_wap()

        # login as that user
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", uid, password)

        # check if report is available
        driver.find_element_by_link_text("Users").click()
        kolabWAPhelper.wait_loading()
        self.assertEquals(-1, driver.page_source.find('href="#userreport"'), "should not display link to User Report")
        self.assertEquals(-1, driver.page_source.find('href="#adminreport"'), "should not display link to Admin Report")

        # should get empty page when going to report directly
        # execute_script does not work: JavascriptException: Message: TypeError: 'blur' called on an object that does not implement interface Window.
        #driver.execute_script("return kadm.command('user.userreport', '', this)");
        #kolabWAPhelper.wait_loading(1)
        # TODO currently this is still possible. but the user can see quota and last login anyway of other users at the moment
        #self.assertEquals(-1, driver.page_source.find('<th>Quota Usage</th>'), "should not display the Report");

        kolabWAPhelper.logout_kolab_wap() 

    def test_user_admin_role(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_user_admin_role")
        driver = self.driver

        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        username, emailLogin, password, uid = kolabWAPhelper.create_user(
            prefix = "user", role = "kolab-admin")

        kolabWAPhelper.logout_kolab_wap()

        # login as that user
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", uid, password)

        # check if report is available
        driver.find_element_by_link_text("Users").click()
        kolabWAPhelper.wait_loading()
        self.assertNotEquals(-1, driver.page_source.find('href="#userreport"'), "should display link to User Report")
        self.assertNotEquals(-1, driver.page_source.find('href="#adminreport"'), "should display link to Admin Report")

        # should see the report
        driver.find_element_by_xpath("//li[@class=\"userreport\"]/a").click()
        kolabWAPhelper.wait_loading(1)
        self.assertNotEquals(-1, driver.page_source.find('<th>Quota Usage</th>'), "should display the Report");

        kolabWAPhelper.logout_kolab_wap()

    def test_domain_admin(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_domain_admin")
        driver = self.driver

        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        username, emailLogin, password, domainname = kolabWAPhelper.create_domainadmin()

        kolabWAPhelper.logout_kolab_wap()

        # login as that user
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", username, password)

        # check if report is available
        driver.find_element_by_link_text("Users").click()
        kolabWAPhelper.wait_loading()
        self.assertNotEquals(-1, driver.page_source.find('href="#userreport"'), "should display link to User Report")
        self.assertNotEquals(-1, driver.page_source.find('href="#adminreport"'), "should display link to Admin Report")

        # should see the report
        driver.find_element_by_xpath("//li[@class=\"userreport\"]/a").click()
        kolabWAPhelper.wait_loading(1)
        self.assertNotEquals(-1, driver.page_source.find('<th>Quota Usage</th>'), "should display the Report");

        kolabWAPhelper.logout_kolab_wap()

    def test_directory_manager(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_directory_manager")
        driver = self.driver

        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        # check if report is available
        driver.find_element_by_link_text("Users").click()
        kolabWAPhelper.wait_loading()
        self.assertNotEquals(-1, driver.page_source.find('href="#userreport"'), "should display link to User Report")
        self.assertNotEquals(-1, driver.page_source.find('href="#adminreport"'), "should display link to Admin Report")

        # should see the report
        driver.execute_script("return kadm.command('user.userreport', '', this)");
        kolabWAPhelper.wait_loading(1)
        self.assertNotEquals(-1, driver.page_source.find('<th>Quota Usage</th>'), "should display the Report");

        kolabWAPhelper.logout_kolab_wap()

    def tearDown(self):
        
        self.kolabWAPhelper.tear_down()

if __name__ == "__main__":
    unittest.main()


