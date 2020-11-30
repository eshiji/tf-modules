#!/bin/bash
echo "Hello from EC2-infra!"

apt update -y
apt install -y apache2

# Creating 
echo "#### $cname $servn
<VirtualHost *:80>
ServerName 
ServerAlias $alias
DocumentRoot $dir$cname_$servn
<Directory $dir$cname_$servn>
Options Indexes FollowSymLinks MultiViews
AllowOverride All
Order allow,deny
Allow from all
Require all granted
</Directory>
</VirtualHost>" > /etc/httpd/conf.d/$cname_$servn.conf

