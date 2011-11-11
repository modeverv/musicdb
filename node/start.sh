#! /bin/bash
/home/seijiro/.nvm/v0.5.10/bin/forever start  -l node.log -o nodeo.log -e log/nodeo.log --pidfile musicnode.pid web.js

