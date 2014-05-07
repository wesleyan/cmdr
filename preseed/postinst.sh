#!/bin/bash

echo $(date)' Downloading and installing chef' >> /var/log/postinst.log
curl -L https://www.opscode.com/chef/install.sh | sudo bash -s -- -v 11.12.4

echo $(date)' Creating chef dir' >> /var/log/postinst.log
mkdir -p /etc/chef

echo $(date) 'Copying the validation and roles files'
wget http://sw.wesleyan.edu/cmdr/validation.pem
mv validation.pem /etc/chef/validation.pem
wget http://sw.wesleyan.edu/cmdr/roles.json
mv roles.json /etc/chef/roles.json
wget http://sw.wesleyan.edu/cmdr/client.rb
mv client.rb /etc/chef/client.rb

echo $(date) 'Removing currently registered client if it exists' >> /var/log/postinst.log
nc -w 1 sw.wesleyan.edu 62085

echo $(date) 'Configuring chef' >> /var/log/postinst.log
chef-client -j /etc/chef/roles.json -c /etc/chef/client.rb

echo $(date) 'Installation finished'
