#!/usr/bin/env python

import unittest
import time
import datetime
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
import subprocess
from helperKolabWAP import KolabWAPTestHelpers

# assumes that initMultiDomain.sh has been run
# assumes password "test" for Directory Manager
# will modify [kolab] autocreate_folders, renames a folder
# will create a new domain, and a new user inside that new domain
# will check kolab lm if the renamed folder has been created for the user
class KolabAutoCreateFolders(unittest.TestCase):

    def setUp(self):
        self.kolabWAPhelper = KolabWAPTestHelpers()
        self.driver = self.kolabWAPhelper.init_driver()

    def helper_modify_autocreate_folders(self):
        # read kolab.conf
        fo = open("/etc/kolab/kolab.conf", "r+")
        content = fo.read()
        fo.close()
        
        newContactsFolderName = "Contacts" + datetime.datetime.now().strftime("%H%M%S")

        # find [kolab], find line starting with 'Contacts, replace with 'Contacts125559': {
        pos = content.index("[kolab]")
        pos = content.index("'Contacts", pos)
        posAfter = content.index(": {", pos)
        
        content = content[:pos] + "'" + newContactsFolderName + "'" + content[posAfter:]
        
        # write kolab.conf
        fo = open("/etc/kolab/kolab.conf", "wb")
        fo.write(content)
        fo.close()

        # restart kolabd to pickup the changed kolab.conf file
        self.kolabWAPhelper.startKolabServer("restart")
        
        self.kolabWAPhelper.log("kolab.conf has been changed, autocreate_folders now contains " + newContactsFolderName)
        
        return newContactsFolderName

    def test_modified_foldername(self):

        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log ("Running test: test_modified_foldername")
        
        # login
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        #modify the default folders in /etc/kolab/kolab.conf
        newContactsFolderName = self.helper_modify_autocreate_folders()

        username, emailLogin, password, uid = kolabWAPhelper.create_user()

        kolabWAPhelper.logout_kolab_wap()

        # check if mailbox has been created, with the modified folder name
        out = ""
        starttime=datetime.datetime.now()
        while newContactsFolderName not in out and (datetime.datetime.now()-starttime).seconds < 60:
           kolabWAPhelper.wait_loading(1)
           p = subprocess.Popen(kolabWAPhelper.getCmdListMailboxes() + " | grep " + username, shell=True, stdout=subprocess.PIPE)
           out, err = p.communicate()
        if newContactsFolderName not in out:
           self.assertTrue(False, "kolab lm cannot find mailbox with folder " + newContactsFolderName + " for new user " + username)

    def test_modified_foldername_in_new_domain(self):

        kolabWAPhelper = self.kolabWAPhelper
        kolabWAPhelper.log ("Running test: test_modified_foldername_in_new_domain")
        
        # login
        kolabWAPhelper.login_kolab_wap("/kolab-webadmin", "cn=Directory Manager", "test")

        domainname = kolabWAPhelper.create_domain()

        #modify the default folders in /etc/kolab/kolab.conf
        newContactsFolderName = self.helper_modify_autocreate_folders()

        username, emailLogin, password, uid = kolabWAPhelper.create_user()

        kolabWAPhelper.logout_kolab_wap()

        # check if mailbox has been created, with the modified folder name
        out = ""
        starttime=datetime.datetime.now()
        while newContactsFolderName not in out and (datetime.datetime.now()-starttime).seconds < 60:
           kolabWAPhelper.wait_loading(1)
           p = subprocess.Popen(kolabWAPhelper.getCmdListMailboxes() + " | grep " + username, shell=True, stdout=subprocess.PIPE)
           out, err = p.communicate()
        if newContactsFolderName not in out:
            self.assertTrue(False, "kolab lm cannot find mailbox with folder " + newContactsFolderName + " for new user " + username)

    def tearDown(self):
        self.kolabWAPhelper.tear_down()

if __name__ == "__main__":
    unittest.main()


