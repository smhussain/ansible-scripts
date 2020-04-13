#!/bin/bash -x
#
# Licensed Materials - Property of IBM
# 5725-X36
# (C) Copyright IBM Corp. 2017. All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#

LOGFILE="install_nodejs.log"

echo "---start installing node.js workload ---" | tee -a ${LOGFILE} 2>&1

curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.0/install.sh | bash
export NVM_DIR="${HOME}/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

nvm install v4.1.2
nvm use v4.1.2
sleep 5
node -e "console.log('Running Node.js ' + process.version)"

cat > mongodb-org-3.4.repo << '  EOF'
[mongodb-org-3.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2013.03/mongodb-org/3.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.4.asc
  EOF

sudo mv -f mongodb-org-3.4.repo /etc/yum.repos.d/mongodb-org-3.4.repo
sudo yum install -y mongodb-org
sleep 5
sudo service mongod start
sudo tail /var/log/mongodb/mongod.log
sudo chkconfig mongod on

unzip appair-nodejs-master.zip
cd acmeair-nodejs-master

sed -e "s/\"port\":9080/\"port\":80/g" settings.json > settings.json.new
sleep 1
mv -f settings.json.new settings.json

npm install
sleep 5
nohup node app.js > acme_nodejs_out 2>&1 &
sleep 5

cd ${HOME}
echo "Loading customers on to Acme Air Application"
curl -X GET http://localhost:80/rest/api/loader/load?numCustomers=10000

echo "Getting the count of bookings..."
curl -X GET http://localhost:80/rest/api/config/countBookings

echo "---finish installing node.js workload---" | tee -a ${LOGFILE} 2>&1
