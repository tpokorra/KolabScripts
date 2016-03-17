import unittest
import time
import datetime
import string
import subprocess
import os
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait # available since 2.4.0
from selenium.webdriver.support import expected_conditions as EC # available since 2.26.0
from selenium.common.exceptions import TimeoutException

import pykolab
import pykolab.base

from pykolab import utils
from pykolab.constants import *
from pykolab.errors import *
from pykolab.translate import _
from pykolab import imap_utf7
from pykolab.imap import IMAP
from pykolab import wap_client

conf = pykolab.getConf()
conf.finalize_conf()
conf.read_config("/etc/kolab/kolab.conf")

# useful functions for testing kolab-webadmin
class KolabWAPTestHelpers(unittest.TestCase):

    def __init__(self):
        unittest.TestCase.__init__(self, '__init__')
        self.imap = None

    def init_driver(self):
        webdriver.DesiredCapabilities.PHANTOMJS['phantomjs.page.customHeaders.Accept-Language'] = 'en-US'
        # support self signed ssl certificate: see also https://github.com/detro/ghostdriver/issues/233
        #webdriver.DesiredCapabilities.PHANTOMJS['ACCEPT_SSL_CERTS'] = 'true'
        self.driver = webdriver.PhantomJS('phantomjs', port=50000, service_args=['--ignore-ssl-errors=true', '--ssl-protocol=tlsv1'])
        self.driver.maximize_window()
        
        #self.driver = webdriver.Firefox()

        return self.driver

    def log(self, message):
        print datetime.datetime.now().strftime("%H:%M:%S") + " " + message

    def getConf(self, section, attribute):
        return conf.get(section, attribute)

    def getCmdListMailboxes(self):
        return "kolab list-mailboxes --server='127.0.0.1:9993' "

    def getSiteUrl(self):
        api_url = self.getConf('kolab_wap', 'api_url')
        if api_url is None:
          return "http://localhost"
        posSlash = api_url.index("/")
        posSlash = api_url.index("/", posSlash+1)
        posSlash = api_url.index("/", posSlash+1)
        # should return https://localhost or http://localhost
        return api_url[:posSlash]

    def getLDAPValue(self, entry_dn, attribute):
        self.ldap = ldap.ldapobject.ReconnectLDAPObject(
                self.getConf('ldap', 'ldap_uri'),
                trace_level=0,
                retry_max=200,
                retry_delay=3.0
            )

        self.ldap.protocol_version = 3
        self.ldap.supported_controls = []

        bind_dn=self.getConf('ldap', 'bind_dn')
        bind_pw=self.getConf('ldap', 'bind_pw')
        try:
            self.ldap.simple_bind_s(bind_dn, bind_pw)
        except ldap.SERVER_DOWN:
           print("server down.")
        except ldap.INVALID_CREDENTIALS:
           print("Invalid DN, username and/or password.")

        attributes = [attribute]
        _search = self.ldap.search_ext(
                entry_dn,
                ldap.SCOPE_BASE,
                filterstr='(objectclass=*)',
                attrlist=[ 'dn' ] + attributes
            )

        (
                _result_type,
                _result_data,
                _result_msgid,
                _result_controls
            ) = self.ldap.result3(_search)

        if len(_result_data) >= 1:
            (_entry_dn, _entry_attrs) = _result_data[0]
            entry_attrs = utils.normalize(_entry_attrs)
            if entry_attrs.has_key(attribute):
              return entry_attrs[attribute]
            elif entry_attrs.has_key(attribute.lower()):
              return entry_attrs[attribute.lower()]
            else:
              return None
        else:
            return None

    def wait_loading(self, initialwait=0.5):
        time.sleep(initialwait)
        while (self.driver.page_source.find('div id="loading"') != -1 and self.driver.page_source.find('id="message"') == -1) or (self.driver.page_source.find('id="message">Loading...') != -1) or (self.driver.page_source.find('id="message"><div class="loading">Loading...') != -1):
            self.log("loading")
            time.sleep(0.5)

    # login any user to the kolab webadmin 
    def login_kolab_wap(self, url, username, password, expected_error = None):
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

        if expected_error is not None:
            elem = driver.find_element_by_id("message")
            self.assertEquals("Incorrect username or password!", elem.text, "Message after failed Login: " + elem.text)
            return False
        else:
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
        driver.find_element_by_class_name("mainaction").click()
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

    def startKolabServer(self, cmd = 'start'):
        if os.path.isfile('/bin/systemctl') and os.path.isfile('/etc/debian_version'):
            subprocess.call(['/bin/systemctl', cmd, 'kolab-server'])
        elif os.path.isfile('/bin/systemctl'):
            subprocess.call(['/bin/systemctl', cmd, 'kolabd.service'])
        elif os.path.isfile('/sbin/service'):
            subprocess.call(['/sbin/service', 'kolabd', cmd])
        elif os.path.isfile('/usr/sbin/service'):
            subprocess.call(['/usr/sbin/service','kolab-server', cmd])
        else:
            self.log(_("Could not %s the kolab server service.") % (cmd))

    def stopKolabServer(self):
        self.startKolabServer('stop')

    def restartKolabServer(self):
        self.startKolabServer('restart')

    def startKolabSync(self, domainname = None):
        # first one run that waits for the sync to finish
        if domainname is not None:
          domainparam = "--domain=" + domainname + " "
        os.system("su - kolab -s /bin/bash -c 'kolab sync " + domainname + "> /dev/null 2>&1'")
        # now start the service again
        self.startKolabServer()

    # create a new domain and select it
    def create_domain(self, domainadmin = None, withAliasDomain = False):

        # stop kolabd service, otherwise we need to wait up to 10 minutes for the domain to be created
        self.stopKolabServer()

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
            elem = driver.find_element_by_xpath("//input[@name='domainadmin[-1]']")
            elem.send_keys(domainadmin)
            self.wait_loading(0.5)
            driver.find_element_by_xpath("//div[@id='autocompletepane']/ul/li[@class='selected']").click()

        elem = driver.find_element_by_xpath("//input[@value=\"Submit\"]")
        elem.click()
        self.wait_loading()
        elem = driver.find_element_by_xpath("//div[@id=\"message\"]")
        self.assertEquals("Domain created successfully.", elem.text, "domain was not created successfully, message: " + elem.text)

        self.startKolabSync(domainname)
        wap_client.authenticate()
        dna = conf.get('ldap', 'domain_name_attribute')
        # wait a couple of seconds until the sync script has been run
        starttime=datetime.datetime.now()
        domain_created=False
        while not domain_created and (datetime.datetime.now()-starttime).seconds < 30:
          time.sleep(1)
          domains = wap_client.domains_list()

          if isinstance(domains['list'], dict):
            for domain_dn in domains['list'].keys():
              if isinstance(domains['list'][domain_dn][dna], list):
                if domains['list'][domain_dn][dna][0] == domainname:
                  domain_created=True
              else:
                if domains['list'][domain_dn][dna] == domainname:
                  domain_created=True

        if not domain_created:
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
        # restart kolabd service, otherwise we need to wait up to 10 minutes for the folder to be created
        self.stopKolabServer()

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

        driver.find_element_by_xpath("//select[@id='aclacl']/option[text()='anyone']").click()
        driver.find_element_by_xpath("//td[@class='buttons']/input[1]").click()
        self.wait_loading(1.0)
        driver.find_element_by_xpath("//select[@id='acl-type']/option[@value='all']").click()
        driver.find_element_by_xpath("//div[@class='modal_btn_buttonok']").click()
        
        self.wait_loading(1.0)
        elem = driver.find_element_by_xpath("//input[@value=\"Submit\"]")
        elem.click()

        self.wait_loading()
        elem = driver.find_element_by_xpath("//div[@id=\"message\"]")

        self.assertEquals("Shared folder created successfully.", elem.text, "Shared Folder was not saved successfully, message: " + elem.text)

        self.startKolabSync(self.get_selected_domain())
        # wait a couple of seconds until the sync script has been run
        out = ""
        starttime=datetime.datetime.now()
        while emailSharedFolder not in out and (datetime.datetime.now()-starttime).seconds < 60:
            self.wait_loading(1)
            p = subprocess.Popen(self.getCmdListMailboxes() + " | grep " + emailSharedFolder, shell=True, stdout=subprocess.PIPE)
            out, err = p.communicate()

        if emailSharedFolder not in out:
            self.assertTrue(False, "kolab list-mailboxes cannot find shared folder " + emailSharedFolder)

        self.wait_loading(2.0)
        subprocess.call(['/bin/bash', '-c', self.getCmdListMailboxes() + " | grep " + emailSharedFolder])
        subprocess.call(['/bin/bash', '-c', "kolab lam shared/" + emailSharedFolder])

        self.log("Shared Folder " + emailSharedFolder + " has been created")

        return emailSharedFolder, foldername

    # create new user account in currently selected domain
    # this is an overload of create_user_return_uid that does not return the uid
    def create_user(self,
                    prefix = "user",
                    overall_quota = None,
                    default_quota = None,
                    max_accounts = None,
                    default_quota_verify = None,
                    default_role_verify = None,
                    mail_quota = None,
                    username = None,
                    uid = None,
                    alias = None,
                    forward_to = None,
                    expected_message_contains = None):
        username, emailLogin, password, uid = self.create_user_return_uid(prefix,
                    overall_quota,
                    default_quota,
                    max_accounts,
                    default_quota_verify,
                    default_role_verify,
                    mail_quota,
                    username,
                    uid,
                    alias,
                    forward_to,
                    expected_message_contains)
        return username, emailLogin, password

    # create new user account in currently selected domain
    def create_user_return_uid(self,
                    prefix = "user",
                    overall_quota = None,
                    default_quota = None,
                    max_accounts = None,
                    default_quota_verify = None,
                    default_role_verify = None,
                    mail_quota = None,
                    username = None,
                    uid = None,
                    alias = None,
                    forward_to = None,
                    expected_message_contains = None):
        # restart kolabd service, otherwise we need to wait up to 10 minutes for the mailbox to be created
        self.stopKolabServer()

        driver = self.driver
        driver.get(driver.current_url)
        elem = driver.find_element_by_link_text("Users")
        elem.click()
        self.wait_loading()
        elem = driver.find_element_by_xpath("//span[@class=\"formtitle\"]")
        self.assertEquals("Add User", elem.text, "form should have title Add User, but was: " + elem.text)

        elem = driver.find_element_by_xpath("//select[@name='type_id']/option[@selected='selected']")
        self.assertEquals("Kolab User", elem.text, "Expected that Kolab User would be the default user type")

        elem = driver.find_element_by_name("givenname")
        if username is None:
            username = prefix + datetime.datetime.now().strftime("%Y%m%d%H%M%S")
        elem.send_keys(username)
        elem = driver.find_element_by_name("sn");
        elem.send_keys(username)
        self.wait_loading(1.0)

        if forward_to is not None:
            # create a user of account type Mail Forwarding
            self.wait_loading(1.0)
            driver.find_element_by_xpath("//select[@name='type_id']/option[text()='Mail Forwarding']").click()
            self.wait_loading(1.0)
            driver.find_element_by_link_text("Configuration").click()
            self.wait_loading(1.0)
            elem = driver.find_element_by_name("mailforwardingaddress[0]")
            elem.send_keys(forward_to)

        if prefix=="admin":
            self.configure_domain_admin(overall_quota, default_quota, max_accounts)

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
        password = "Test1234!."
        elem.send_keys(password)
        elem = driver.find_element_by_name("userpassword2")
        elem.clear()
        elem.send_keys(password)

        elem = driver.find_element_by_name("uid")
        if uid is not None:
            elem.clear()
            elem.send_keys(uid)
        else:
            uid = elem.get_attribute("value")

        elem = driver.find_element_by_xpath("//input[@value=\"Submit\"]")
        elem.click()

        self.wait_loading(1)
        elem = driver.find_element_by_xpath("//div[@id=\"message\"]")
        if expected_message_contains is not None:
            self.assertNotEquals(-1, elem.text.find(expected_message_contains), "User should not have been created, message should contain: " + expected_message_contains + " but was: " + elem.text)
            return

        self.assertEquals("User created successfully.", elem.text, "User was not saved successfully, message: " + elem.text)

        self.startKolabSync(self.get_selected_domain()) 
        if forward_to is None:
            if self.imap is None:
              self.imap = IMAP()
              self.imap.connect()
            wap_client.authenticate()
            # wait a couple of seconds until the sync script has been run (perhaps even the domain still needs to be created?)
            starttime=datetime.datetime.now()
            user_created=False
            while not user_created and (datetime.datetime.now()-starttime).seconds < 60:
              time.sleep(1)
              folders = []
              folders.extend(self.imap.lm(imap_utf7.encode('*')))

              for folder in folders:
                if username in folder or username in imap_utf7.decode(folder):
                  user_created=True

            if not user_created:
                self.assertTrue(False, "kolab list-mailboxes cannot find mailbox for new user " + username)

        self.log("User " + username + " has been created. Login with " + emailLogin + " and password " + password)

        return username, emailLogin, password, uid

    def configure_domain_admin(self, overall_quota, default_quota, max_accounts):
        driver = self.driver
        elem = driver.find_element_by_link_text("Domain Administrator")
        elem.click()
        driver.find_element_by_xpath("//input[@name='tbitskolabisdomainadmin']").click()

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

    def upgrade_user_to_domainadmin(self, username, domainname,
                    overall_quota = None,
                    default_quota = None,
                    max_accounts = None):
        driver = self.driver
        self.load_user(username)
        self.configure_domain_admin(overall_quota, default_quota, max_accounts)
        elem = driver.find_element_by_xpath("//input[@value=\"Submit\"]")
        elem.click()

        self.wait_loading(1)
        elem = driver.find_element_by_xpath("//div[@id=\"message\"]")
        self.assertEquals("User updated successfully.", elem.text, "User was not saved successfully, message: " + elem.text)

        self.link_admin_to_domain(username, domainname)

    # create a new domain, and create a domain admin for that domain, inside that domain
    def create_domainadmin(self,
                    overall_quota = None,
                    default_quota = None,
                    max_accounts = None,
                    default_quota_verify = None,
                    default_role_verify = None,
                    mail_quota = None,
                    username = None,
                    alias = None,
                    forward_to = None,
                    expected_message_contains = None):
        driver=self.driver
        domainname = self.create_domain()
        (username, emailLogin, password) = self.create_user("admin",
              overall_quota, default_quota, max_accounts, default_quota_verify, default_role_verify, mail_quota, username, alias, forward_to, expected_message_contains)
        self.link_admin_to_domain(username, domainname)
        return username, emailLogin, password, domainname

    def link_admin_to_domain(self, username, domainname):
        driver = self.driver

        # now edit the domain and set the domainadmin
        driver.find_element_by_link_text("Domains").click()
        self.wait_loading(1.0)
        elem = self.driver.find_element_by_id("searchinput")
        elem.send_keys(domainname)
        elem.send_keys(Keys.ENTER)
        self.wait_loading(initialwait = 2)
        elem = self.driver.find_element_by_xpath("//table[@id='domainlist']/tbody/tr/td")
        self.assertEquals(domainname, elem.text, "Expected to select domain " + domainname + " but was " + elem.text)
        elem.click()
        self.wait_loading(initialwait = 1)
        elem = driver.find_element_by_link_text("Domain Administrators")
        elem.click()
        elem = driver.find_element_by_xpath("//input[@name='domainadmin[-1]']")
        elem.send_keys(username)
        self.wait_loading(0.5)
        driver.find_element_by_xpath("//div[@id='autocompletepane']/ul/li[@class='selected']").click()
        elem = driver.find_element_by_xpath("//input[@value=\"Submit\"]")
        elem.click()
        self.wait_loading()
        elem = driver.find_element_by_xpath("//div[@id=\"message\"]")
        self.assertEquals("Domain updated successfully.", elem.text, "domain was not updated successfully, message: " + elem.text)

    def load_user(self, username):

        self.driver.get(self.driver.current_url)
        self.driver.find_element_by_link_text("Users").click()
        self.wait_loading(1.0) 

        elem = self.driver.find_element_by_id("searchinput")
        elem.send_keys(username)
        elem.send_keys(Keys.ENTER)
        self.wait_loading(initialwait = 2)

        elem = self.driver.find_element_by_xpath("//table[@id='userlist']/tbody/tr/td")
        self.assertEquals(username + ", " + username, elem.text, "Expected to select user " + username + " but was " + elem.text)
        elem.click()

        self.wait_loading(initialwait = 1)

    def send_email(self, recipientEmailAddress):
        driver = self.driver
        emailSubjectLine = "subject" + datetime.datetime.now().strftime("%Y%m%d%H%M%S")

        driver.find_element_by_xpath("//div[@id=\"messagetoolbar\"]/a[contains(@class,'button') and contains(@class,'compose')]").click()
        self.wait_loading()
        elem = driver.find_element_by_name("_to")
        elem.send_keys(recipientEmailAddress)
        elem = driver.find_element_by_name("_subject")
        elem.send_keys(emailSubjectLine)
        elem = driver.find_element_by_name("_message")
        elem.send_keys("Hello World")
        driver.find_element_by_xpath("//div[@id=\"messagetoolbar\"]/a[@class=\"button send\"]").click()
        self.wait_loading(20)

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
        self.wait_loading(5)
        if emailSubjectLine is not None:
           elem = wait.until(EC.visibility_of_element_located(
                      (By.XPATH, "//div[@id='messageheader']/h2[text()='" + emailSubjectLine + "']")),
                   "the first email does not have the subject " + emailSubjectLine)
        if emailSubjectLineDoesNotContain is not None:
           try:
             elem = wait.until(EC.visibility_of_element_located((By.XPATH, "//div[@id='messageheader']/h2[text()='" + emailSubjectLineDoesNotContain + "']")),
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

    def tear_down(self):
        # write current page for debugging purposes
        self.log_current_page()

        if self.imap:
          self.imap.disconnect()

        self.driver.quit()

