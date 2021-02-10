#!/bin/bash

apt update -y
apt install -y acl

# Install docker
apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt update -y
apt-cache policy docker-ce
apt install -y docker-ce
systemctl enable docker
pip3 install docker

# Configure openvpn user
adduser openvpn
usermod -aG sudo openvpn
usermod -aG docker openvpn
echo  -e 'openvpn\tALL=(ALL)\tNOPASSWD:\tALL' > /etc/sudoers.d/openvpn

pip3 install docker