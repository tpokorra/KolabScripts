#!/usr/bin/env python

import unittest
import time
import datetime
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from helperKolabWAP import KolabWAPTestHelpers

# assumes password for cn=Directory Manager is test.
# assumes that the initTBitsISP.sh script has been run.
# will create a domain admin user, with a overall quota (type domainadmin)
# will create a new domain, and assign that domain admin user as domain administrator
# will create users inside that new domain (type normal kolab user)
# will check that the domain quota is observed
class KolabWAPDomainAdmin(unittest.TestCase):

    def setUp(self):
        self.driver = webdriver.Firefox()

    def test_domain_admin(self):
        kolabWAPhelper = KolabWAPTestHelpers(self.driver)
        self.kolabWAPhelper = kolabWAPhelper
        
        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("http://localhost/kolab-webadmin", "cn=Directory Manager", "test")

        kolabWAPhelper.select_domain("administrators.org")

        username, emailLogin, password = kolabWAPhelper.create_user(
            prefix = "admin",
            overall_quota = "1gb",
            default_quota = "100mb",
            max_accounts = 3,
            allow_groupware = True)

        # TODO create domain, with domain admin
        # TODO select domain
        # TODO create user accounts

    def tearDown(self):
        
        # write current page for debugging purposes
        self.kolabWAPhelper.log_current_page()
        
        self.driver.close()

if __name__ == "__main__":
    unittest.main()


