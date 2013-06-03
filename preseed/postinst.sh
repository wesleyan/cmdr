#!/bin/bash

echo $(date)' Downloading the chef deb' >> /var/log/postinst.log
/usr/bin/wget http://ims-chef.wesleyan.edu/roomtrol/chef_11.4.2-1.ubuntu.11.04_amd64.deb

echo $(date)' Installing chef' >> /var/log/postinst.log
dpkg -i chef_11.4.2-1.ubuntu.11.04_amd64.deb

echo $(date)' Creating chef dir' >> /var/log/postinst.log
mkdir -p /etc/chef

echo $(date) 'copying the validation and roles files'
wget http://ims-chef.wesleyan.edu/roomtrol/validation.pem
mv validation.pem /etc/chef/validation.pem
wget http://ims-chef.wesleyan.edu/roomtrol/roles.json
mv roles.json /etc/chef/roles.json
wget http://ims-chef.wesleyan.edu/roomtrol/client.rb
mv client.rb /etc/chef/client.rb

echo $(date) 'removing old client' >> /var/log/postinst.log
nc -w 1 ims-chef.wesleyan.edu 62085

echo $(date) 'installing chef' >> /var/log/postinst.log
chef-client -j /etc/chef/roles.json -c /etc/chef/client.rb

echo $(date) 'Installation finished'
