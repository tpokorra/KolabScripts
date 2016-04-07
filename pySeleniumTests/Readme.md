Instructions
============
Please also see http://www.pokorra.de/2013/11/kolab-integration-tests-with-selenium-and-python/

Install Selenium:
```sh
yum install python-selenium
```

You can use PhantomJS with Selenium to have a headless browser. It is based on Webkit.

```sh
yum install phantomjs
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
