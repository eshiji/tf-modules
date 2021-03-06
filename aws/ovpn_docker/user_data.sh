Content-Type: multipart/mixed; boundary="//"
MIME-Version: 1.0

--//
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="cloud-config.txt"

#cloud-config
cloud_final_modules:
- [scripts-user, always]

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"

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
chown -R ${user}.${user} /home/${user}

# Mount s3fs
echo ${bucket_name} /home/${user}/${user}-files/ fuse.s3fs _netdev,uid=$(id -u ${user}),gid=$(id -g ${user}),allow_other,nonempty,iam_role=${iam_role_name} 0 0 >> /etc/fstab
/usr/bin/s3fs ${bucket_name} -o use_cache=/tmp,iam_role=${iam_role_name} /home/${user}/${user}-files/
mount -a 

--//
