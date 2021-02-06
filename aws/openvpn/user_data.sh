#!/bin/bash

apt update -y
adduser openvpn
usermod -aG sudo openvpn