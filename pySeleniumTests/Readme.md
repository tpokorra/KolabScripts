Instructions
============
Please also see http://kolab.org/blog/timotheus-pokorra/2013/11/19/kolab-integration-tests-selenium-and-python

Install Selenium:
```sh
sudo yum install python-setuptools python-unittest2
sudo easy_install selenium 
```

You can use PhantomJS with Selenium to have a headless browser. It is based on Webkit.
You need to download a binary once, from http://phantomjs.org/download.html:

```sh
wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.7-linux-x86_64.tar.bz2
tar xjf phantomjs-1.9.7-linux-x86_64.tar.bz2
cp phantomjs-1.9.7-linux-x86_64/bin/phantomjs /usr/bin
```

Please also install the mail package because it is required by some tests:

```sh
yum install mail
```

Then you can just start the tests like this:
```sh
cd KolabScripts/pySeleniumTests
./testAutoCreateFolders.py
./testCreateUserAndEditSelf.py KolabWAPCreateUserAndEditSelf.test_edit_user_himself
```

To run all tests:
```sh
./runTests.sh
```
