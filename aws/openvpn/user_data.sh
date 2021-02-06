#!/bin/bash

apt update -y
adduser openvpn
usermod -aG sudo openvpn
echo  -e 'openvpn\tALL=(ALL)\tNOPASSWD:\tALL' > /etc/sudoers.d/openvpn
