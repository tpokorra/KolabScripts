#!/usr/bin/env python

import unittest
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from helperKolabWAP import KolabWAPTestHelpers

# assumes password for cn=Directory Manager is test.
# assumes that the initTBitsISP.sh script has been run.
# will create a domain admin user, with and without groupware enabled
# will create a new domain, and assign that domain admin user as domain administrator
# will create users inside that new domain
# will check that the domain admin can enable groupware features or not
class KolabWAPDomainAdmin(unittest.TestCase):

    def setUp(self):
        self.kolabWAPhelper = KolabWAPTestHelpers()
        self.driver = self.kolabWAPhelper.init_driver()

    def test_enabled_groupware_features(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_enabled_groupware_features")
        
        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("http://localhost/kolab-webadmin", "cn=Directory Manager", "test")

        kolabWAPhelper.select_domain("administrators.org")

        username, emailLogin, password = kolabWAPhelper.create_user(
            prefix = "admin")
            # enabled by default: allow_groupware = True

        # create domains, with domain admin
        domainname = kolabWAPhelper.create_domain(username)
        
        # create user account. role enable-groupware-features should be set by default
        kolabWAPhelper.create_user(default_role_verify = "enable-groupware-features")

        kolabWAPhelper.logout_kolab_wap()

    def test_disabled_groupware_features(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_disabled_groupware_features")
        
        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("http://localhost/kolab-webadmin", "cn=Directory Manager", "test")

        kolabWAPhelper.select_domain("administrators.org")

        username, emailLogin, password = kolabWAPhelper.create_user(
            prefix = "admin",
            allow_groupware = False)

        # create domains, with domain admin
        domainname = kolabWAPhelper.create_domain(username)
        
        # create user account. role enable-groupware-features should not be set
        kolabWAPhelper.create_user(default_role_verify = "")

        # TODO: create role enable-groupware-features for the domain
        # TODO: create a new user with role enable-groupware-features, should fail!

        kolabWAPhelper.logout_kolab_wap()

    def tearDown(self):
        
        # write current page for debugging purposes
        self.kolabWAPhelper.log_current_page()
        
        self.driver.close()

if __name__ == "__main__":
    unittest.main()


