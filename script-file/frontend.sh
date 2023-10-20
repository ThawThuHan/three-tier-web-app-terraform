#!/bin/bash
yum update -y
yum install httpd -y
systemctl enable --now httpd
echo "frontend" > /var/www/html/index.html