import unittest
import time
import datetime
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
import subprocess

# assumes password for cn=Directory Manager is test
# will create a new user, and try to login is that user and change the initials
# will check kolab lm if the calendar folder has been created for the user
class KolabWAPCreateUserAndEditSelf(unittest.TestCase):

    def setUp(self):
        self.driver = webdriver.Firefox()

    def helper_create_user(self):
        driver = self.driver
        driver.get("http://localhost/kolab-webadmin")
        self.assertEquals("Kolab Web Admin Panel", driver.title, "title should be Kolab WAP but was: " + driver.title)

        # login the Directory Manager
        elem = driver.find_element_by_id("login_name")
        elem.send_keys("cn=Directory Manager")
        elem = driver.find_element_by_id("login_pass")
        elem.send_keys("test")
        elem.send_keys(Keys.RETURN)

        # verify success of login
        elem = driver.find_element_by_class_name("login")
        self.assertEquals("Directory Manager", elem.text, "user logged in should be the Directory Manager, but was: " + elem.text)

        # create new user account
        elem = driver.find_element_by_xpath("//div[@class=\"user\"]")
        self.assertEquals("Users", elem.text, "expected users but was: " + elem.text)
        elem.click()
        time.sleep(5)
        #print driver.page_source
        elem = driver.find_element_by_xpath("//span[@class=\"formtitle\"]")
        #elem = driver.find_element_by_class_name("formtitle")
        self.assertEquals("Add User", elem.text, "form should have title Add User, but was: " + elem.text)
        elem = driver.find_element_by_name("givenname")
        username = "test" + datetime.datetime.now().strftime("%Y%m%d%H%M%S");
        elem.send_keys(username)
        elem = driver.find_element_by_name("sn");
        elem.send_keys(username)
	# store the email address for later login
        elem = driver.find_element_by_link_text("Contact Information")
        elem.click()
        elem = driver.find_element_by_name("mail")
        emailLogin = elem.get_attribute('value')
        elem = driver.find_element_by_link_text("System")
        elem.click()
        elem = driver.find_element_by_name("userpassword")
        elem.clear()
        elem.send_keys("test")
        elem = driver.find_element_by_name("userpassword2")
        elem.clear()
        elem.send_keys("test")
        elem = driver.find_element_by_xpath("//input[@value=\"Submit\"]")
        elem.click()

        # logout the Directory Manager
        elem = driver.find_element_by_class_name("logout")
        elem.click()

	# check if mailbox has been created
        p = subprocess.Popen("kolab lm | grep " + username + " | grep Calendar", shell=True, stdout=subprocess.PIPE)
        out, err = p.communicate()
        if "Calendar" not in out:
            self.assertTrue(False, "kolab lm cannot find mailbox with folder Calendar for new user " + username)
       
        return username, emailLogin

    def test_edit_user_himself(self):
        # create the user
        username, emailLogin = self.helper_create_user()

        driver = self.driver
        driver.get("http://localhost/kolab-webadmin")

        # login the created user
        elem = driver.find_element_by_id("login_name")
        elem.send_keys(emailLogin)
        elem = driver.find_element_by_id("login_pass")
        elem.send_keys("test")
        elem.send_keys(Keys.RETURN)
        time.sleep(3)

        # verify success of login
        elem = driver.find_element_by_class_name("login")
        self.assertEquals(username + " " + username, elem.text, "user logged in should be the " + username + " " + username + ", but was: " + elem.text)

        # edit yourself
        elem = driver.find_element_by_xpath("//div[@class=\"settings\"]")
        elem.click()
        time.sleep(1)
        #elem = driver.find_element_by_id("searchinput")
        #elem.send_keys(username)
        #elem.send_keys(Keys.RETURN)
        #elem = driver.find_element_by_xpath("//tbody/tr/td[@class=\"name\"]")
        #print elem.text
        #print elem.get_attribute("onclick")
        #elem.click()
        #time.sleep(10)
        #print driver.page_source
        elem = driver.find_element_by_name("initials")
        elem.send_keys("T")
        elem = driver.find_element_by_xpath("//input[@value=\"Submit\"]")
        elem.click()
        time.sleep(2)
        elem = driver.find_element_by_class_name("notice")
        self.assertEquals("User updated successfully.", elem.text, "success message should be displayed, but was: " + elem.text)

    def tearDown(self):
        self.driver.close()

if __name__ == "__main__":
    unittest.main()


