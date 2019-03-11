Instructions
============
Please also see http://www.pokorra.de/2013/11/kolab-integration-tests-with-selenium-and-python/

Install the latest Chromium and geckodriver:

```sh
yum install gtk3 dbus-glib chromedriver chromium-headless
cd /root
version="v0.24.0"
wget https://github.com/mozilla/geckodriver/releases/download/$version/geckodriver-$version-linux64.tar.gz
tar xzf geckodriver-$version-linux64.tar.gz
ln -s /root/geckodriver /usr/bin/geckodriver
```

Install Xvfb and pip
```sh
yum install Xvfb python2-pip
```

Install Selenium from pip:

```sh
pip2 install selenium pyvirtualdisplay
```

Please also install the mail package because it is required by some tests:

```sh
yum install mail
```

Create a profile for the tests:

```sh
xvfb-run firefox -CreateProfile "SeleniumTests /tmp/SeleniumTests"
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
