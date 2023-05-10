#!/bin/bash

yum update -y
yum install -y httpd
yum install -y wget
cd /var/www/html
echo "Hello World" >> /var/www/html/index.html
systemctl start httpd
systemctl enable httpd