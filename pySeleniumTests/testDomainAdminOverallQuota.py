#!/usr/bin/env python

import unittest
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from helperKolabWAP import KolabWAPTestHelpers

# assumes password for cn=Directory Manager is test.
# assumes that the initTBitsISP.sh script has been run.
# will create a domain admin user, with a overall quota (type domainadmin)
# will create a new domain, and assign that domain admin user as domain administrator
# will create users inside that new domain
# will check that the domain quota is observed
class KolabWAPDomainAdmin(unittest.TestCase):

    def setUp(self):
        self.kolabWAPhelper = KolabWAPTestHelpers()
        self.driver = self.kolabWAPhelper.init_driver()

    # check that domain admin cannot assign too much quota to the user accounts
    def test_overall_quota_limit(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_overall_quota_limit")
        
        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        username, emailLogin, password = kolabWAPhelper.create_user(
            prefix = "admin",
            overall_quota = "800mb")

        # create domains, with domain admin
        domainname = kolabWAPhelper.create_domain(username)
        domainname2 = kolabWAPhelper.create_domain(username)
        
        # create user accounts
        kolabWAPhelper.select_domain(domainname)
        # test if no account has been created yet, validation will still kick in
        kolabWAPhelper.create_user(mail_quota = "2gb", expected_message_contains = "mailquota of the domain admin has been exceeded")
        kolabWAPhelper.create_user(mail_quota = "200mb")
        kolabWAPhelper.select_domain(domainname2)
        # should fail, exceeding the overall quota of the domain admin
        kolabWAPhelper.create_user(mail_quota = "900mb", expected_message_contains = "mailquota of the domain admin has been exceeded")
        kolabWAPhelper.create_user(mail_quota = "600mb")

        kolabWAPhelper.logout_kolab_wap()

    # test that a domain admin with a mail quota cannot create user mailboxes with no quota specified
    def test_unlimited_user_quota(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_unlimited_user_quota")
        
        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        username, emailLogin, password = kolabWAPhelper.create_user(
            prefix = "admin",
            overall_quota = "1gb")

        # create domain, with domain admin
        domainname = kolabWAPhelper.create_domain(username)
        
        # create user account
        kolabWAPhelper.create_user(expected_message_contains = "must specify a mailquota for the user")

        kolabWAPhelper.logout_kolab_wap()

    # test that a domain admin with no mail quota can create user mailboxes with as much quota as he wants
    def test_no_quota(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_no_quota")
        
        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        username, emailLogin, password = kolabWAPhelper.create_user(
            prefix = "admin")

        # create domain, with domain admin
        domainname = kolabWAPhelper.create_domain(username)
        
        # create user account with a quota
        kolabWAPhelper.create_user(mail_quota = "100mb")
        # without any quota for the user
        kolabWAPhelper.create_user()

        kolabWAPhelper.logout_kolab_wap()

    def tearDown(self):
        
        # write current page for debugging purposes
        self.kolabWAPhelper.log_current_page()
        
        self.driver.quit()

if __name__ == "__main__":
    unittest.main()


