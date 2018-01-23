#!/usr/bin/env python

import unittest
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from helperKolabWAP import KolabWAPTestHelpers

# assumes password for cn=Directory Manager is test.
# assumes that the initTBitsISP.sh script has been run.
# will create a domain admin user, with a default quota
# will create a new domain, and assign that domain admin user as domain administrator
# will create users inside that new domain
# will check that the default domain quota is used
class KolabWAPDomainAdmin(unittest.TestCase):

    def setUp(self):
        self.kolabWAPhelper = KolabWAPTestHelpers()
        self.driver = self.kolabWAPhelper.init_driver()

    def test_domain_admin_default_quota(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_domain_admin")
        
        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        username, emailLogin, password, uid = kolabWAPhelper.create_user(
            prefix = "admin",
            default_quota = "100mb",
            overall_quota = "300mb")

        # create domains, with domain admin
        domainname = kolabWAPhelper.create_domain(username)
        
        # create user accounts
        # test if default quota is set properly for a new user
        kolabWAPhelper.create_user(default_quota_verify = "100mb")
        kolabWAPhelper.create_user(mail_quota = "150mb")
        kolabWAPhelper.create_user(default_quota_verify = "100mb", expected_message_contains = "mailquota of the domain admin has been exceeded")

        kolabWAPhelper.logout_kolab_wap()

    def tearDown(self):
        self.kolabWAPhelper.tear_down()

if __name__ == "__main__":
    unittest.main()


