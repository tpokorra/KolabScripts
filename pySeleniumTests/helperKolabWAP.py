import unittest
import time
import datetime
from selenium import webdriver
from selenium.webdriver.common.keys import Keys

# useful functions for testing kolab-webadmin
class KolabWAPTestHelpers(unittest.TestCase):

    def __init__(self, driver):
        self.driver = driver

    # login any user to the kolab webadmin 
    def login_kolab_wap(self, url, username, password):
        driver = self.driver
        driver.get(url)

        # login the Directory Manager
        elem = driver.find_element_by_id("login_name")
        elem.send_keys(username)
        elem = driver.find_element_by_id("login_pass")
        elem.send_keys(password)
        elem.send_keys(Keys.RETURN)
        time.sleep(2)

        # verify success of login
        elem = driver.find_element_by_xpath("//span[@class='login']")
        print "User is logged in: " + elem.text

        return True

    # logout the current user
    def logout_kolab_wap(self):
        self.driver.find_element_by_class_name("logout").click()
        print "User has logged out"

    # create a new domain and select it
    def create_domain(self):

        driver = self.driver

        # create new domain
        elem = driver.find_element_by_xpath("//div[@class=\"domain\"]")
        elem.click()
        time.sleep(2)
        elem = driver.find_element_by_name("associateddomain[0]")
        domainname = "domain" + datetime.datetime.now().strftime("%Y%m%d%H%M%S") + ".de"
        elem.send_keys(domainname)
        elem = driver.find_element_by_xpath("//input[@value=\"Submit\"]")
        elem.click()
        time.sleep(2)
        elem = driver.find_element_by_xpath("//div[@id=\"message\"]")
        self.assertEquals("Domain created successfully.", elem.text, "domain was not created successfully, message: " + elem.text)
        
        # reload so that the domain dropdown is updated, and switch to new domain at the same time
        self.select_domain(domainname)

        return domainname

    def select_domain(self, domainname):
        driver = self.driver
        driver.get(driver.current_url + "domain=" + domainname)
        elem = driver.find_element_by_id("selectlabel_domain")
        self.assertEquals(domainname, elem.text, "selected domain: expected " + domainname + " but was " + elem.text)

        print "Domain " + domainname + " has been selected"

    # create new user account in currently selected domain
    def create_user(self,
                    prefix = "user",
                    overall_quota = None,
                    default_quota = None,
                    max_accounts = None,
                    allow_groupware = None):
        driver = self.driver

        elem = driver.find_element_by_xpath("//div[@class=\"user\"]")
        self.assertEquals("Users", elem.text, "expected users but was: " + elem.text)
        elem.click()
        time.sleep(2)
        elem = driver.find_element_by_xpath("//span[@class=\"formtitle\"]")
        self.assertEquals("Add User", elem.text, "form should have title Add User, but was: " + elem.text)
        elem = driver.find_element_by_name("givenname")
        username = prefix + datetime.datetime.now().strftime("%Y%m%d%H%M%S");
        elem.send_keys(username)
        elem = driver.find_element_by_name("sn");
        elem.send_keys(username)

        if overall_quota is not None or default_quota is not None or max_accounts is not None or allow_groupware is not None:
            elem = driver.find_element_by_link_text("Domain Administrator")
            elem.click()
            if overall_quota is not None:
                elem = driver.find_element_by_name("tbitskolaboverallquota")
                elem.send_keys(overall_quota[:-2])
                driver.find_element_by_xpath("//select[@name='tbitskolaboverallquota-unit']/option[@value='" + overall_quota[-2:] + "']").click()
            if default_quota is not None:
                elem = driver.find_element_by_name("tbitskolabdefaultquota")
                elem.send_keys(default_quota[:-2])
                driver.find_element_by_xpath("//select[@name='tbitskolabdefaultquota-unit']/option[@value='" + default_quota[-2:] + "']").click()
            if max_accounts is not None:
                elem = driver.find_element_by_name("tbitskolabmaxaccounts")
                elem.send_keys(max_accounts)
            if allow_groupware is not None:
                elem = driver.find_element_by_name("tbitskolaballowgroupware")
                elem.click()

        # store the email address for later login
        elem = driver.find_element_by_link_text("Contact Information")
        elem.click()
        elem = driver.find_element_by_name("mail")
        emailLogin = elem.get_attribute('value')
        
        elem = driver.find_element_by_link_text("System")
        elem.click()
        elem = driver.find_element_by_name("userpassword")
        elem.clear()
        password = "test"
        elem.send_keys(password)
        elem = driver.find_element_by_name("userpassword2")
        elem.clear()
        elem.send_keys(password)

        elem = driver.find_element_by_xpath("//input[@value=\"Submit\"]")
        elem.click()

        print "User " + username + " has been created. Login with " + emailLogin + " and password " + password

        return username, emailLogin, password

    def log_current_page(self):
        fo = open("/tmp/output.html", "wb")
        fo.write(self.driver.page_source.encode('utf-8'))
        fo.close()
        print
        print "self.driver.page_source has been written to /tmp/output.html"
