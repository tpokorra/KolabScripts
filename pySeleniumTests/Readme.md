Instructions
============
Please also see http://www.pokorra.de/2013/11/kolab-integration-tests-with-selenium-and-python/

Install the latest Firefox and geckodriver:

```sh
yum install gtk3
cd /root
wget https://download-installer.cdn.mozilla.net/pub/firefox/releases/57.0/linux-x86_64/en-US/firefox-57.0.tar.bz2
tar xjf firefox-57.0.tar.bz2
ln -s /root/firefox/firefox /usr/bin/firefox
wget https://github.com/mozilla/geckodriver/releases/download/v0.19.1/geckodriver-v0.19.1-linux64.tar.gz
tar xzf geckodriver-v0.19.1-linux64.tar.gz
ln -s /root/geckodriver /usr/bin/geckodriver
```

Install Xvfb and pip
```sh
yum install Xvfb pip
```

Install Selenium from pip:

```sh
pip install selenium pyvirtualdisplay
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
