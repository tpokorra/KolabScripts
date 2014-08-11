import unittest
import time
import datetime
import string
import subprocess
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait # available since 2.4.0
from selenium.webdriver.support import expected_conditions as EC # available since 2.26.0
from selenium.common.exceptions import TimeoutException

# useful functions for testing kolab-webadmin
class KolabWAPTestHelpers(unittest.TestCase):

    def __init__(self):
        return

    def init_driver(self):
        webdriver.DesiredCapabilities.PHANTOMJS['phantomjs.page.customHeaders.Accept-Language'] = 'en-US'
        # support self signed ssl certificate: see also https://github.com/detro/ghostdriver/issues/233
        #webdriver.DesiredCapabilities.PHANTOMJS['ACCEPT_SSL_CERTS'] = 'true'
        self.driver = webdriver.PhantomJS('phantomjs', service_args=['--ignore-ssl-errors=true'])
        self.driver.maximize_window()
        
        #self.driver = webdriver.Firefox()

        return self.driver

    def log(self, message):
        print datetime.datetime.now().strftime("%H:%M:%S") + " " + message

    def getSiteUrl(self):
        # read kolab.conf
        fo = open("/etc/kolab/kolab.conf", "r+")
        content = fo.read()
        fo.close()

        # find [kolab_wap], find line starting with api_url
        pos = content.index("[kolab_wap]")
        if content.find("api_url", pos) == -1:
          return "http://localhost"
        pos = content.index("api_url", pos)
        pos = content.index("http", pos)
        posSlash = content.index("/", pos)
        posSlash = content.index("/", posSlash+1)
        posSlash = content.index("/", posSlash+1)
        # should return https://localhost or http://localhost
        return content[pos:posSlash]

    def wait_loading(self, initialwait=0.5):
        time.sleep(initialwait)
        while self.driver.page_source.find('div id="loading"') != -1 and self.driver.page_source.find('id="message"') == -1:
            self.log("loading")
            time.sleep(0.5)

    # login any user to the kolab webadmin 
    def login_kolab_wap(self, url, username, password):
        driver = self.driver

        if url[0] == '/':
            url = self.getSiteUrl() + url

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
        self.log( "User is logged in to WAP: " + elem.text)

        return True

    # logout the current user
    def logout_kolab_wap(self):
        self.driver.find_element_by_class_name("logout").click()
        self.log("User has logged out from WAP")

    # login any user to roundcube
    def login_roundcube(self, url, username, password):
        driver = self.driver

        if url[0] == '/':
            url = self.getSiteUrl() + url

        driver.get(url)

        # login the user
        elem = driver.find_element_by_id("rcmloginuser")
        elem.send_keys(username)
        elem = driver.find_element_by_id("rcmloginpwd")
        elem.send_keys(password)
        driver.find_element_by_id("rcmloginsubmit").click()
        self.wait_loading()

        # verify success of login
        if len(driver.find_elements_by_xpath("//div[@id=\"message\"]")) > 0:
          elem = driver.find_element_by_xpath("//div[@id=\"message\"]")
          self.assertEquals("", elem.text, "Message after Login: " + elem.text)
        if self.driver.page_source.find("<title>404 Not Found</title>") != -1:
          self.assertEquals("", "404 not found", "error fetching page")

        elem = driver.find_element_by_class_name("username")
        
        # check that there is no error about non existing mailbox
        if "Server Error: STATUS: Mailbox does not exist" in self.driver.page_source:
          self.assertEquals("no error", "there was an error", "Server Error: STATUS: Mailbox does not exist")

        numberofattempts = 2
        while numberofattempts > 0:
          if "Server Error! (No connection)" in self.driver.page_source:
            if numberofattempts > 0:
              driver.get(url)
              elem = driver.find_element_by_class_name("username")
            else:
              self.assertEquals("no error", "there was an error", "Server Error! (No connection)")
          numberofattempts = numberofattempts - 1

        self.log( "User is logged in to Roundcube: " + elem.text)
        return True

    # logout the current user
    def logout_roundcube(self):
        driver = self.driver
        #self.driver.find_element_by_xpath("//div[@id=\"topnav\"]/div[@id=\"taskbar\"]/a[@class=\"button-logout\"]").click()
        url = driver.current_url[:driver.current_url.find("?")]
        driver.get(url + "?_task=logout")
        self.wait_loading()
        elem = driver.find_element_by_class_name("notice")
        self.assertEquals("You have successfully terminated the session. Good bye!", elem.text, "should have logged out, but was: " + elem.text)
        #driver.delete_all_cookies()
        self.log("User has logged out from Roundcube")

    # create a new domain and select it
    def create_domain(self, domainadmin = None, withAliasDomain = False):

        driver = self.driver
        driver.get(driver.current_url)

        elem = driver.find_element_by_link_text("Domains")
        elem.click()
        self.wait_loading()

        elem = driver.find_element_by_name("associateddomain[0]")
        domainname = "domain" + datetime.datetime.now().strftime("%Y%m%d%H%M%S") + ".de"
        elem.send_keys(domainname)

        if withAliasDomain == True:
            aliasdomainname = string.replace(domainname, "domain", "alias")
            driver.find_element_by_xpath("//textarea[@name=\"associateddomain\"]/following-sibling::*[1]/span[@class=\"listelement\"]/span[@class=\"actions\"]/span[@class=\"add\"]").click()
            elem = driver.find_element_by_xpath("//textarea[@name=\"associateddomain\"]/following-sibling::*[1]/span[2]/input");
            elem.send_keys(aliasdomainname)

        if domainadmin is not None:
            elem = driver.find_element_by_link_text("Domain Administrators")
            elem.click()
            driver.find_element_by_xpath("//select[@name='domainadmin[0]']/option[text()='" + domainadmin + ", " + domainadmin + "']").click()

        elem = driver.find_element_by_xpath("//input[@value=\"Submit\"]")
        elem.click()
        self.wait_loading()
        elem = driver.find_element_by_xpath("//div[@id=\"message\"]")
        self.assertEquals("Domain created successfully.", elem.text, "domain was not created successfully, message: " + elem.text)

        # wait a couple of seconds until the sync script has been run
        out = ""
        starttime=datetime.datetime.now()
        while domainname not in out and (datetime.datetime.now()-starttime).seconds < 30:
          self.wait_loading(1)
          p = subprocess.Popen("kolab list-domains | grep " + domainname, shell=True, stdout=subprocess.PIPE)
          out, err = p.communicate()

        if domainname not in out:
            self.assertTrue(False, "kolab list-domains cannot find domain " + domainname)
  

        self.log("Domain " + domainname + " has been created")
        
        # reload so that the domain dropdown is updated, and switch to new domain at the same time
        self.select_domain(domainname)

        return domainname

    def get_selected_domain(self):
        try:
            elem = self.driver.find_element_by_id("selectlabel_domain")
        except NoSuchElementException, e:
            # there is only one domain, no dropdown control
            elem = self.driver.find_element_by_id("domain-selector")
        return elem.text

    def select_domain(self, domainname):
        driver = self.driver
        url = driver.current_url[:driver.current_url.find("?")]
        driver.get(url + "?domain=" + domainname)
        selecteddomain = self.get_selected_domain()
        self.assertEquals(domainname, selecteddomain, "selected domain: expected " + domainname + " but was " + selecteddomain)
        if not ">Users<" in driver.page_source:
            self.fail("selecting the domain did not work, no users menu item is available")

        self.log("Domain " + domainname + " has been selected")

    # create new shared folder
    # expects a list of delegate email addresses
    def create_shared_folder(self, delegates = None, foldername = None):
        driver = self.driver
        driver.get(driver.current_url)
        elem = driver.find_element_by_link_text("Shared Folders")
        elem.click()
        self.wait_loading()
        elem = driver.find_element_by_xpath("//span[@class=\"formtitle\"]")
        self.assertEquals("Add Shared Folder", elem.text, "form should have title Add Shared Folder, but was: " + elem.text)

        if foldername is None:
            foldername = "folder" + datetime.datetime.now().strftime("%Y%m%d%H%M%S")
        emailSharedFolder = foldername + "@" + self.get_selected_domain()

        # create a shared Mail folder
        driver.find_element_by_xpath("//select[@name='type_id']/option[text()='Shared Mail Folder']").click()
        self.wait_loading(1.0)
        elem = driver.find_element_by_name("cn")
        elem.send_keys(foldername)
        elem = driver.find_element_by_name("mail")
        elem.send_keys(emailSharedFolder)
        if delegates is not None:
            for delegate in delegates:
                elem = driver.find_element_by_name("kolabdelegate[-1]")
                elem.send_keys(delegate)
                self.wait_loading(1.0)
                driver.find_element_by_xpath("//div[@id=\"autocompletepane\"]/ul/li").click()
                self.wait_loading(0.1)

        driver.find_element_by_link_text("Other").click()
        self.wait_loading(1.0)
        elem = driver.find_element_by_name("kolabtargetfolder")
        elem.send_keys("shared/" + emailSharedFolder)
        
        elem = driver.find_element_by_xpath("//input[@value=\"Submit\"]")
        elem.click()

        self.wait_loading()
        elem = driver.find_element_by_xpath("//div[@id=\"message\"]")

        self.assertEquals("Shared folder created successfully.", elem.text, "Shared Folder was not saved successfully, message: " + elem.text)

        self.log("Shared Folder " + emailSharedFolder + " has been created")

        return emailSharedFolder, foldername

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
                    username = None,
                    alias = None,
                    forward_to = None,
                    expected_message_contains = None):
        driver = self.driver
        driver.get(driver.current_url)
        elem = driver.find_element_by_link_text("Users")
        elem.click()
        self.wait_loading()
        elem = driver.find_element_by_xpath("//span[@class=\"formtitle\"]")
        self.assertEquals("Add User", elem.text, "form should have title Add User, but was: " + elem.text)

        # workaround for Kolab 3.1 vanilla: default new account is Contact. Select Kolab User instead
        elem = driver.find_element_by_xpath("//select[@name='type_id']/option[@selected='selected']")
        if elem.text == "Contact":
            driver.find_element_by_xpath("//select[@name='type_id']/option[text()='Kolab User']").click()
            self.wait_loading(1.0)

        elem = driver.find_element_by_name("givenname")
        if username is None:
            username = prefix + datetime.datetime.now().strftime("%Y%m%d%H%M%S")
        elem.send_keys(username)
        elem = driver.find_element_by_name("sn");
        elem.send_keys(username)

        if forward_to is not None:
            # create a user of account type Mail Forwarding
            self.wait_loading(1.0)
            driver.find_element_by_xpath("//select[@name='type_id']/option[text()='Mail Forwarding']").click()
            self.wait_loading(1.0)
            driver.find_element_by_link_text("Configuration").click()
            self.wait_loading(1.0)
            elem = driver.find_element_by_name("mailforwardingaddress[0]")
            elem.send_keys(forward_to)

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
        self.wait_loading(1.0)
        elem = driver.find_element_by_name("mail")
        emailLogin = elem.get_attribute('value')
        self.assertNotEquals(0, emailLogin.__len__(), "email should be set automatically, but length is 0")

        if alias is not None:
            driver.find_element_by_xpath("//textarea[@name=\"alias\"]/following-sibling::*[1]/span[@class=\"listelement\"]/span[@class=\"actions\"]/span[@class=\"add\"]").click()
            elem = driver.find_element_by_xpath("//textarea[@name=\"alias\"]/following-sibling::*[1]/span[2]/input");
            elem.send_keys(alias)
            self.wait_loading(1.0)

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

        if forward_to is None:
            # wait a couple of seconds until the sync script has been run (perhaps even the domain still needs to be created?)
            out = ""
            starttime=datetime.datetime.now()
            while username not in out and (datetime.datetime.now()-starttime).seconds < 60:
                self.wait_loading(1)
                p = subprocess.Popen("kolab list-mailboxes | grep " + username, shell=True, stdout=subprocess.PIPE)
                out, err = p.communicate()

            if username not in out:
                self.assertTrue(False, "kolab list-mailboxes cannot find mailbox for new user " + username)

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
        driver.find_element_by_xpath("//div[@id=\"messagetoolbar\"]/a[@class=\"button send\"]").click()
        self.wait_loading()

        return emailSubjectLine

    def check_email_received(self, folder="INBOX", emailSubjectLine = None, emailSubjectLineDoesNotContain = None):
        driver = self.driver

        url = driver.current_url[:driver.current_url.find("?")]
        driver.get(url + "?_task=mail&_mbox=" + folder)
        self.wait_loading(0.5)

        # check for valid folder
        if "Shared+Folders" in folder:
            if "Server Error: STATUS: Mailbox does not exist" in self.driver.page_source:
                self.assertEquals("no error", "invalid folder", "Folder does not exist: " + folder)
        else:
            # normal folder, should be selected
            # somehow, the error message Mailbox does not exist is not picked up by Selenium when the folder does not exist
            try:
                elem = driver.find_element_by_xpath("//ul[@id=\"mailboxlist\"]/li[contains(@class, 'mailbox " + folder.lower() + " selected')]")
            except NoSuchElementException, e:
                self.assertEquals(folder, "not found", "cannot select the folder " + folder + " " + "//ul[@id=\"mailboxlist\"]/li[@class=\"mailbox " + folder.lower() + " selected\"]")

        wait = WebDriverWait(driver, 10);

        # there seem to be problems to load the message list in Selenium.
        # is the javascript method not run to load the message list?
        # if emailSubjectLine is not None:
        #   elem = wait.until(EC.visibility_of_element_located(
        #              (By.XPATH, "//table[@id=\"messagelist\"]/tbody/tr/td[@class=\"subject\"]/a[text()='" + emailSubjectLine + "']")),
        #          "cannot find the email with subject " + emailSubjectLine)
        # if emailSubjectLineDoesNotContain is not None:
        #   try:
        #     elem = wait.until(EC.visibility_of_element_located((By.XPATH, "//table[@id=\"messagelist\"]/tbody/tr/td[@class=\"subject\"]/a[text()='" + emailSubjectLineDoesNotContain + "'")),
        #          "cannot find the email with subject " + emailSubjectLineDoesNotContain);
        #     self.assertTrue(False, "email subject should not contain " + emailSubjectLineDoesNotContain + " but was " + elem.text)
        #   except TimeoutException, e:
        #     self.assertTrue(True, "we expect a timeout, since we don't want to find the email with this subject") 

        # roundcubemail/?_task=mail&_action=show&_uid=1&_mbox=INBOX
        driver.get(url + "?_task=mail&_action=show&_uid=1&_mbox=" + folder)
        if emailSubjectLine is not None:
           elem = wait.until(EC.visibility_of_element_located(
                      (By.XPATH, "//h2[@class='subject'][text()='" + emailSubjectLine + "']")),
                   "the first email does not have the subject " + emailSubjectLine)
        if emailSubjectLineDoesNotContain is not None:
           try:
             elem = wait.until(EC.visibility_of_element_located((By.XPATH, "//h2[@class='subject'][text()='" + emailSubjectLineDoesNotContain + "']")),
                  "cannot find the email with subject " + emailSubjectLineDoesNotContain);
             self.assertTrue(False, "email subject should not contain " + emailSubjectLineDoesNotContain + " but was " + elem.text)
           except TimeoutException, e:
             self.assertTrue(True, "we expect a timeout, since we don't want to find the email with this subject as the first email") 

    def log_current_page(self):
        filename = "/tmp/output" + datetime.datetime.now().strftime("%Y%m%d%H%M%S") + ".html"
        fo = open(filename, "wb")
        fo.write(self.driver.page_source.encode('utf-8'))
        fo.close()
        self.log("self.driver.page_source has been written to " + filename)
        print 
