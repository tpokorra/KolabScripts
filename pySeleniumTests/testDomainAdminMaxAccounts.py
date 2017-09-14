#!/usr/bin/env python

import unittest
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from helperKolabWAP import KolabWAPTestHelpers

# assumes password for cn=Directory Manager is test.
# assumes that the initTBitsISP.sh script has been run.
# will create a domain admin user, with a maximum number of 3 accounts
# will create 2 new domains for this admin
# will create users inside that new domain
# will check that it fails to create a 5th account, across the domains
class KolabWAPDomainAdmin(unittest.TestCase):

    def setUp(self):
        self.kolabWAPhelper = KolabWAPTestHelpers()
        self.driver = self.kolabWAPhelper.init_driver()

    def test_max_accounts(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_max_accounts")
        
        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        username, emailLogin, password, domainname = kolabWAPhelper.create_domainadmin(
            max_accounts = 3)

        # create another domain, with domain admin
        domainname2 = kolabWAPhelper.create_domain(username)

        # create user accounts
        kolabWAPhelper.select_domain(domainname)
        kolabWAPhelper.create_user()
        kolabWAPhelper.create_user()
        kolabWAPhelper.select_domain(domainname2)
        kolabWAPhelper.create_user()
        # should fail, only 3 accounts allowed, excluding the domain admin
        kolabWAPhelper.create_user(expected_message_contains = "Cannot create another account")

        # create another domain admin, for the same domains, but with higher max_accounts
        username2, emailLogin2, password2, domainname3 = kolabWAPhelper.create_domainadmin(
            max_accounts = 7)
        kolabWAPhelper.link_admin_to_domain(username2, domainname)
        kolabWAPhelper.link_admin_to_domain(username2, domainname2)
        # should still fail, because the domain admin with the smallest amount of accounts booked applies
        kolabWAPhelper.select_domain(domainname)
        kolabWAPhelper.create_user(expected_message_contains =
            "Cannot create another account")

        # select the third domain, where the second domain admin is allowed to create more accounts
        kolabWAPhelper.select_domain(domainname3)
        kolabWAPhelper.create_user()
        kolabWAPhelper.create_user()
        kolabWAPhelper.create_user()
        kolabWAPhelper.create_user()
        # should fail, only 7 accounts allowed, excluding the domain admin
        kolabWAPhelper.create_user(expected_message_contains = "Cannot create another account")

        kolabWAPhelper.logout_kolab_wap()

    def tearDown(self):
        
        # write current page for debugging purposes
        self.kolabWAPhelper.log_current_page()
        
        self.driver.quit()

if __name__ == "__main__":
    unittest.main()


