#!/bin/bash

apt update -y
apt install -y acl s3fs python3-pip

# Install docker
apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt update -y
apt-cache policy docker-ce
apt install -y docker-ce
systemctl enable docker
pip3 install docker

# Configure "${user}"
adduser ${user}
usermod -aG sudo ${user}
usermod -aG docker ${user}
echo  -e '${user}\tALL=(ALL)\tNOPASSWD:\tALL' > /etc/sudoers.d/${user}
mkdir -p /home/${user}/${user}-files
chown -R ${user}.${user} /home/${user}/${user}-files

# Mount s3fs
/usr/bin/s3fs ${bucket_name} -o use_cache=/tmp,iam_role=${iam_role_name},uid=1000,gid=1000,allow_other /home/${user}/${user}-files/
 echo ${bucket_name} /home/${user}/${user}-files/ fuse.s3fs _netdev,allow_other 0 0 >> /etc/fstab

