import unittest
import time
import datetime
from selenium import webdriver
from selenium.webdriver.common.keys import Keys

# useful functions for testing kolab-webadmin
class KolabWAPTestHelpers(unittest.TestCase):

    def __init__(self):
        return

    def init_driver(self):
        webdriver.DesiredCapabilities.PHANTOMJS['phantomjs.page.customHeaders.Accept-Language'] = 'en-US'
        # support self signed ssl certificate: see also https://github.com/detro/ghostdriver/issues/233
        #webdriver.DesiredCapabilities.PHANTOMJS['ACCEPT_SSL_CERTS'] = 'true'
        self.driver = webdriver.PhantomJS('phantomjs', service_args=['--ignore-ssl-errors=true'])
        
        #self.driver = webdriver.Firefox()

        return self.driver

    def log(self, message):
        print datetime.datetime.now().strftime("%H:%M:%S") + " " + message

    def wait_loading(self, initialwait=0.5):
        time.sleep(initialwait)
        while self.driver.page_source.find('div id="loading"') != -1 and self.driver.page_source.find('id="message"') == -1:
            self.log("loading")
            time.sleep(0.5)

    # login any user to the kolab webadmin 
    def login_kolab_wap(self, url, username, password):
        driver = self.driver

        if url[0] == '/':
            url = "https://localhost" + url

        driver.get(url)

        # login the user
        elem = driver.find_element_by_id("login_name")
        elem.send_keys(username)
        elem = driver.find_element_by_id("login_pass")
        elem.send_keys(password)
        driver.find_element_by_id("login_submit").click()
        self.wait_loading()

        # verify success of login
        elem = driver.find_element_by_class_name("login")
        self.log( "User is logged in: " + elem.text)

        return True

    # logout the current user
    def logout_kolab_wap(self):
        self.driver.find_element_by_class_name("logout").click()
        self.log("User has logged out")

    # login any user to roundcube
    def login_roundcube(self, url, username, password):
        driver = self.driver

        if url[0] == '/':
            url = "https://localhost" + url

        driver.get(url)

        # login the user
        elem = driver.find_element_by_id("rcmloginuser")
        elem.send_keys(username)
        elem = driver.find_element_by_id("rcmloginpwd")
        elem.send_keys(password)
        driver.find_element_by_xpath("//form/p/input[@class='button mainaction']").click()
        self.wait_loading()

        # verify success of login
        elem = driver.find_element_by_class_name("username")
        self.log( "User is logged in: " + elem.text)
        return True

    # logout the current user
    def logout_roundcube(self):
        driver = self.driver
        #self.driver.find_element_by_xpath("//div[@id=\"topnav\"]/div[@id=\"taskbar\"]/a[@class=\"button-logout\"]").click()
        url = driver.current_url[:driver.current_url.find("?")]
        driver.get(url + "?_task=logout")
        self.wait_loading()
        elem = driver.find_element_by_class_name("notice")
        self.assertEquals("You have successfully terminated the session. Good bye!", elem.text, "should have logged out")
        self.log("User has logged out")

    # create a new domain and select it
    def create_domain(self, domainadmin = None):

        driver = self.driver
        driver.get(driver.current_url)

        elem = driver.find_element_by_link_text("Domains")
        elem.click()
        self.wait_loading()

        elem = driver.find_element_by_name("associateddomain[0]")
        domainname = "domain" + datetime.datetime.now().strftime("%Y%m%d%H%M%S") + ".de"
        elem.send_keys(domainname)

        if domainadmin is not None:
            elem = driver.find_element_by_link_text("Domain Administrators")
            elem.click()
            driver.find_element_by_xpath("//select[@name='domainadmin[0]']/option[text()='" + domainadmin + ", " + domainadmin + "']").click()

        elem = driver.find_element_by_xpath("//input[@value=\"Submit\"]")
        elem.click()
        self.wait_loading()
        elem = driver.find_element_by_xpath("//div[@id=\"message\"]")
        self.assertEquals("Domain created successfully.", elem.text, "domain was not created successfully, message: " + elem.text)
        
        self.log("Domain " + domainname + " has been created")
        
        # reload so that the domain dropdown is updated, and switch to new domain at the same time
        self.select_domain(domainname)

        return domainname

    def select_domain(self, domainname):
        driver = self.driver
        url = driver.current_url[:driver.current_url.find("?")]
        driver.get(url + "?domain=" + domainname)
        elem = driver.find_element_by_id("selectlabel_domain")
        self.assertEquals(domainname, elem.text, "selected domain: expected " + domainname + " but was " + elem.text)

        self.log("Domain " + domainname + " has been selected")

    # create new user account in currently selected domain
    def create_user(self,
                    prefix = "user",
                    overall_quota = None,
                    default_quota = None,
                    max_accounts = None,
                    allow_groupware = None,
                    default_quota_verify = None,
                    default_role_verify = None,
                    mail_quota = None,
                    expected_message_contains = None):
        driver = self.driver
        driver.get(driver.current_url)
        elem = driver.find_element_by_link_text("Users")
        elem.click()
        self.wait_loading()
        elem = driver.find_element_by_xpath("//span[@class=\"formtitle\"]")
        self.assertEquals("Add User", elem.text, "form should have title Add User, but was: " + elem.text)
        elem = driver.find_element_by_name("givenname")
        username = prefix + datetime.datetime.now().strftime("%Y%m%d%H%M%S")
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

        if mail_quota is not None or default_quota_verify is not None:
            elem = driver.find_element_by_link_text("Configuration")
            elem.click()
            if default_quota_verify is not None:
                elem = driver.find_element_by_name("mailquota")
                self.assertEquals(default_quota_verify[:-2], 
                        elem.get_attribute('value'), 
                        "default quota should be " + default_quota_verify + " but was " + elem.get_attribute('value'))
                elem = driver.find_element_by_xpath("//select[@name='mailquota-unit']/option[@selected='selected']")
                self.assertEquals(default_quota_verify[-2:], 
                        elem.get_attribute('value'), 
                        "default quota should be " + default_quota_verify + " but was " + elem.get_attribute('value'))
            if mail_quota is not None:
                elem = driver.find_element_by_name("mailquota")
                elem.clear()
                elem.send_keys(mail_quota[:-2])
                driver.find_element_by_xpath("//select[@name='mailquota-unit']/option[@value='" + mail_quota[-2:] + "']").click()

        if default_role_verify is not None:
            elem = driver.find_element_by_link_text("System")
            elem.click()
            if default_role_verify == '':
                if self.driver.page_source.find("nsroledn[0]") != -1:
                    elem = driver.find_element_by_name("nsroledn[0]")
                    self.assertEquals(default_role_verify,
                        elem.get_attribute('value'), 
                        "default role should be empty but was " + elem.get_attribute('value'))
            else:
                if self.driver.page_source.find("nsroledn[0]") == -1:
                    self.assertEquals(default_role_verify,
                        '',
                        "default role should be " + default_role_verify + " but was empty")
                elem = driver.find_element_by_name("nsroledn[0]")
                self.assertEquals(default_role_verify,
                        elem.get_attribute('value'), 
                        "default role should be " + default_role_verify + " but was " + elem.get_attribute('value'))
            

        # store the email address for later login
        elem = driver.find_element_by_link_text("Contact Information")
        elem.click()
        elem = driver.find_element_by_name("mail")
        # somehow a short wait is necessary for the email to be calculated from firstname and surname
        time.sleep(0.5)
        emailLogin = elem.get_attribute('value')
        self.assertNotEquals(0, emailLogin.__len__(), "email should be set automatically, but length is 0")
        
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

        self.wait_loading()
        elem = driver.find_element_by_xpath("//div[@id=\"message\"]")
        if expected_message_contains is not None:
            self.assertNotEquals(-1, elem.text.find(expected_message_contains), "User should not have been created, message should contain: " + expected_message_contains + " but was: " + elem.text)
            return

        self.assertEquals("User created successfully.", elem.text, "User was not saved successfully, message: " + elem.text)

        self.log("User " + username + " has been created. Login with " + emailLogin + " and password " + password)

        return username, emailLogin, password

    def send_email(self, recipientEmailAddress):
        driver = self.driver
        emailSubjectLine = "subject" + datetime.datetime.now().strftime("%Y%m%d%H%M%S")

        driver.find_element_by_xpath("//div[@id=\"messagetoolbar\"]/a[@class=\"button compose\"]").click()
        self.wait_loading()
        elem = driver.find_element_by_name("_to")
        elem.send_keys(recipientEmailAddress)
        elem = driver.find_element_by_name("_subject")
        elem.send_keys(emailSubjectLine)
        elem = driver.find_element_by_name("_message")
        elem.send_keys("Hello World")
        driver.find_element_by_xpath("//div[@id=\"mailtoolbar\"]/a[@class=\"button send\"]").click()
        self.wait_loading()

        return emailSubjectLine

    def check_email_received(self, emailSubjectLine):
        driver = self.driver

        url = driver.current_url[:driver.current_url.find("?")]
        driver.get(url + "?_task=mail&_mbox=INBOX")
        self.wait_loading(0.5)
        driver.find_element_by_xpath("//ul[@id=\"mailboxlist\"]/li[starts-with(@class, \"mailbox inbox\")]").click()
        self.wait_loading()
        
        elem = driver.find_element_by_xpath("//table[@id=\"messagelist\"]/tbody/tr/td[@class=\"subject\"]/a")
        self.assertEquals(emailSubjectLine, elem.text, "email subject should be " + emailSubjectLine + " but was " + elem.text)

    def log_current_page(self):
        filename = "/tmp/output" + datetime.datetime.now().strftime("%Y%m%d%H%M%S") + ".html"
        fo = open(filename, "wb")
        fo.write(self.driver.page_source.encode('utf-8'))
        fo.close()
        self.log("self.driver.page_source has been written to " + filename)
        print 
