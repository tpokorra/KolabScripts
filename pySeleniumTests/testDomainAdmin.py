#!/usr/bin/env python

import unittest
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from helperKolabWAP import KolabWAPTestHelpers

# assumes password for cn=Directory Manager is test.
# assumes that the initTBitsISP.sh script has been run.
# will create a new domain, and a new domain admin inside that domain, and assign that domain admin user as domain administrator for the domain
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
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        username, emailLogin, password, uid = kolabWAPhelper.create_user(
            prefix = "user")

        # now edit the user
        kolabWAPhelper.load_user(username)

        # check if the user type is actually a normal kolab user
        elem = self.driver.find_element_by_xpath("//form[@id='user-form']/fieldset/table/tbody/tr/td[@class='value']")
        self.assertEquals("Kolab User", elem.text, "user type should be Kolab User, but was " + elem.text)

        kolabWAPhelper.logout_kolab_wap()

    def test_domain_admin_with_own_domain(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_domain_admin_with_own_domain")

        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        username, emailLogin, password, domainname = kolabWAPhelper.create_domainadmin()

        # some tests if the domain admin has been stored in LDAP as expected
        # there should not be the objectClass: mailrecipient
        # there should not be mail: or alias:
        ldapuid="uid="+username+",ou=People,dc=" + ",dc=".join(domainname.split("."))
        value = kolabWAPhelper.getLDAPValue(ldapuid, 'objectClass')
        if 'mailrecipient' in value:
            self.assertIsNone(value, "we don't want objectClass mailrecipient for domainadmins but there is " + str(value))
        value = kolabWAPhelper.getLDAPValue(ldapuid, 'mail', '*')
        self.assertIsNone(value, "we don't want an attribute mail for domainadmins but there is " + str(value))
        value = kolabWAPhelper.getLDAPValue(ldapuid, 'alias', '*')
        self.assertIsNone(value, "we don't want an attribute alias for domainadmins but there is " + str(value))

        # now edit the user
        self.driver.get(self.driver.current_url)
        elem = self.driver.find_element_by_link_text("Users")
        elem.click()
        kolabWAPhelper.wait_loading()
        elem = self.driver.find_element_by_id("searchinput")
        elem.send_keys(username)
        elem.send_keys(Keys.ENTER)
        kolabWAPhelper.wait_loading(initialwait = 2)

        elem = self.driver.find_element_by_xpath("//table[@id='userlist']/tbody/tr/td")
        self.assertEquals(username + ", " + username, elem.text, "Expected to select user " + username + " but was " + elem.text)
        elem.click()

        kolabWAPhelper.wait_loading(initialwait = 1)

        # check if the user type is a Kolab Domain Administrator
        elem = self.driver.find_element_by_xpath("//form[@id='user-form']/fieldset/table/tbody/tr/td[@class='value']")
        self.assertEquals("Domain Administrator", elem.text, "user type should be Domain Administrator, but was " + elem.text)

        kolabWAPhelper.logout_kolab_wap()

    # test that domain admin cannot edit its own maxaccount / overallquota
    def test_domain_admin_edit_own_parameters(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_domain_admin_edit_own_parameters")

        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        username, emailLogin, password, domainname = kolabWAPhelper.create_domainadmin()
        kolabWAPhelper.logout_kolab_wap()

        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", emailLogin, password)
        elem = self.driver.find_element_by_xpath("//div[@class=\"settings\"]")
        elem.click()
        self.kolabWAPhelper.wait_loading()
        elem = self.driver.find_element_by_link_text("Domain Administrator")
        elem.click()
        self.kolabWAPhelper.wait_loading()
        # the domain admin should not be able to edit his own parameters, eg max accounts
        elem = self.driver.find_element_by_xpath("//input[@name=\"tbitskolabmaxaccounts\"]")
        if not "readonly" in elem.get_attribute('class'):
          self.assertTrue(False, "maxaccounts should be readonly for the domain admin")
        # also not tbitskolaboverallquota
        elem = self.driver.find_element_by_xpath("//input[@name=\"tbitskolaboverallquota\"]")
        if not "readonly" in elem.get_attribute('class'):
          self.assertTrue(False, "overallquota should be readonly for the domain admin")

        kolabWAPhelper.logout_kolab_wap()

    # test if the domain admin can add users to his domain
    def test_domain_admin_create_user(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_domain_admin_edit_create_user")

        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        username, emailLogin, password, domainname = kolabWAPhelper.create_domainadmin()
        kolabWAPhelper.logout_kolab_wap()

        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", emailLogin, password)
        # check selected domain is correct
        currentdomain=kolabWAPhelper.get_selected_domain()
        self.assertEquals(domainname, currentdomain, "should have selected domain " + domainname)
        kolabWAPhelper.create_user()
        kolabWAPhelper.logout_kolab_wap()

    # test if ex-domain admin cannot add users
    def test_ex_domain_admin_without_permission(self):
        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log("Running test: test_ex_domain_admin_without_permission")

        # login Directory Manager
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        username, emailLogin, password, domainname = kolabWAPhelper.create_domainadmin()

        # now withdraw domainadmin permissions for this domain
        kolabWAPhelper.unlink_admin_from_domain(username, domainname)
 
        kolabWAPhelper.logout_kolab_wap()

        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", emailLogin, password)
        # check selected domain is correct
        currentdomain=kolabWAPhelper.get_selected_domain()
        self.assertEquals(domainname, currentdomain, "should have selected domain " + domainname)

        self.driver.find_element_by_link_text("Users").click()
        kolabWAPhelper.wait_loading()

        didFail=True
        try:
          elem = self.driver.find_element_by_xpath("//span[@class=\"formtitle\"]")
          didFail=False
        except:
          # all is fine, there should not be a Add User title, but an empty box
          pass

        if not didFail:
          self.assertTrue(False, "ex-domain admin should not be able to create new accounts")

        kolabWAPhelper.logout_kolab_wap()
        
    def tearDown(self):
        
        self.kolabWAPhelper.tear_down()
        
        self.driver.quit()

if __name__ == "__main__":
    unittest.main()


