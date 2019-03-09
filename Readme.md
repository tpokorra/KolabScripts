Attention
=========

Please use the scripts only if you understand them. We don't give any guarantuee that they will work or will destroy your data.


Contributing
============

You are welcome to provide Pull requests on Github, if you spot a problem or want to suggest an improvement!


Layout
======

We have organised the scripts according to the releases.
Please have a look in the branches.
So if you want to work with Kolab 16, go to https://github.com/TBits/KolabScripts/tree/Kolab16

For more details, please visit the wiki at https://github.com/tbits/kolabscripts/wiki


Tests with Cypress
==================

prepare installation:

    curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -
    yum -y install nodejs libXScrnSaver GConf2 Xvfb
    npm install cypress

Test with a GUI:

    LANG=en CYPRESS_baseUrl=https://localhost ./node_modules/.bin/cypress open

Test on the command line:

    LANG=en CYPRESS_baseUrl=https://localhost ./node_modules/.bin/cypress run --config video=false

