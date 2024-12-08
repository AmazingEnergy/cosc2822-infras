#!/bin/bash

# Turn on password authentication for lab challenge
echo 'lab-password' | passwd ec2-user --stdin
sed -i 's|[#]*PasswordAuthentication no|PasswordAuthentication yes|g' /etc/ssh/sshd_config
systemctl restart sshd.service

echo 'start install mysql'

# Update the system
sudo dnf update -y

sudo dnf -y localinstall https://dev.mysql.com/get/mysql80-community-release-el9-4.noarch.rpm

# Install MySQL server
sudo dnf -y install mysql mysql-community-client
sudo dnf -y install mysql-community-server
sudo yum update -y
sudo yum install mysql -y

# Enable and start MySQL service
sudo systemctl enable mysqld
sudo systemctl start mysqld

# Log the status of the MySQL service
sudo systemctl status mysqld >> /var/log/mysql-install.log

echo 'finish setup mysql'