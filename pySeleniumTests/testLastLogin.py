#!/usr/bin/env python

import unittest
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from helperKolabWAP import KolabWAPTestHelpers

# assumes password for cn=Directory Manager is test.
# assumes that the initTBitsISP.sh script has been run.
# will create a new user
# will login with this new user to roundcube
# will check the last login time
class KolabWAPLastLogin(unittest.TestCase):

    def setUp(self):
        self.kolabWAPhelper = KolabWAPTestHelpers()
        self.driver = self.kolabWAPhelper.init_driver()

    def test_last_login(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_last_login")
        
        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        username, emailLogin, password, uid = kolabWAPhelper.create_user()
        kolabWAPhelper.logout_kolab_wap()

        # login the new user
        kolabWAPhelper.login_roundcube("/roundcubemail", emailLogin, password)
        kolabWAPhelper.logout_roundcube()

        # check that the last login timestamp is greater than 1 January 2014
        value = kolabWAPhelper.getLDAPValue("uid="+username+",ou=People," + kolabWAPhelper.getConf('ldap', 'base_dn'), 'tbitsKolabLastLogin')
        self.assertTrue(int(value) > 1388534400, "login date should be after 1 January 2014")

        # last login time will only be updated after an hour, so we cannot test that here. see pykolab/auth/ldap/auth_cache.py purge_entries

    def test_last_login_in_other_domain(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_last_login_in_other_domain")
        
        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        domainname = kolabWAPhelper.create_domain()

        username, emailLogin, password, uid = kolabWAPhelper.create_user()
        kolabWAPhelper.logout_kolab_wap()

        # login the new user
        kolabWAPhelper.login_roundcube("/roundcubemail", emailLogin, password)
        kolabWAPhelper.logout_roundcube()

        # check that the last login timestamp is greater than 1 January 2014
        value = kolabWAPhelper.getLDAPValue("uid="+username+",ou=People,dc=" + ",dc=".join(domainname.split(".")), 'tbitsKolabLastLogin')
        self.assertTrue(int(value) > 1388534400, "login date should be after 1 January 2014")

        # last login time will only be updated after an hour, so we cannot test that here. see pykolab/auth/ldap/auth_cache.py purge_entries

    def tearDown(self):
        self.kolabWAPhelper.tear_down()

if __name__ == "__main__":
    unittest.main()


