Instructions
============
Please also see http://kolab.org/blog/timotheus-pokorra/2013/11/19/kolab-integration-tests-selenium-and-python

You can use PhantomJS with Selenium to have a headless browser. It is based on Webkit.
You need to download a binary once, from http://phantomjs.org/download.html:

```sh
wget https://phantomjs.googlecode.com/files/phantomjs-1.9.2-linux-x86_64.tar.bz2
tar xjf phantomjs-1.9.2-linux-x86_64.tar.bz
cp phantomjs-1.9.2-linux-x86_64/bin/phantomjs /usr/bin
```

Then you can just start the tests like this:
```sh
cd kolab3_tbits_scripts/pySeleniumTests
./testAutoCreateFolders.py
```

To run all tests:
```sh
for f in *.py; do ./$f; done
```
