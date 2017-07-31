#!/bin/bash

# Base config constants
EBS_DEVICE='/dev/xvdb'
TF2_USER_NAME=''
TF2_USER_PASS=''
TF2_ROOT='/home/'$TF2_USER_NAME/$TF2_USER_NAME
TF2_HOST=''
TF2_MAIL_HOST='locahost'
TF2_LABEL=''
RCON_PASS=''
TF2_ADMIN_EMAIL=''

# Create a system user for the
# Team Fortress 2 server
mkdir -p $TF2_ROOT  # Note: useradd on Ubuntu does not auto-create the home directory
useradd $TF2_USER_NAME -d /home/$TF2_USER_NAME
usermod -aG sudo $TF2_USER_NAME
usermod -aG admin $TF2_USER_NAME
echo -e "$TF2_USER_PASS\n$TF2_USER_PASS" | passwd $TF2_USER_NAME
echo $TF2_USER_NAME" ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers  # TODO: find a better way to write to this file
echo "sudo su tf2server" >> /home/ubuntu/.profile
echo "cd /home/tf2server" >> /home/ubuntu/.profile

# Update package manager and install required packages
apt-get update -y
# apt-get upgrade -y
dpkg --add-architecture i386
apt-get update -y
debconf-set-selections <<EOF
"postfix postfix/mailname string $TF2_MAIL_HOST"
EOF
debconf-set-selections <<EOF
"postfix postfix/main_mailer_type string 'No configuration'"
EOF
apt-get install -y postfix
apt-get install -y mailutils curl screen wget file bzip2 gzip unzip bsdmainutils python util-linux tmux lib32gcc1 libstdc++6 libstdc++6:i386 libcurl4-gnutls-dev:i386
apt-get install -y expect

# Mount ESB to TF2 server root directory and
# recursively change ownership to $TF2_USER_NAME
mkfs -t ext4 $EBS_DEVICE
mount $EBS_DEVICE $TF2_ROOT # TODO: Configure to mount on reboot
chown $TF2_USER_NAME:$TF2_USER_NAME -R /home/$TF2_USER_NAME

# Generate the expect script that will run tf2server installer automatically
cd $TF2_ROOT
touch tf2server_expect_install.sh
cat > tf2server_expect_install.sh <<-EOF
#!/usr/bin/expect -f
spawn $TF2_ROOT/tf2server install
expect "Continue? \\\\\\[Y/n\\\\\\] Y"
send "\r"
set timeout 60
expect "\\\\\\[sudo\\\\\\] password for tf2server: "
send "$TF2_USER_PASS"
set timeout 60
expect "Was the install successful? \\\\\\[Y/n\\\\\\] Y"
send "\r"
set timeout 600
expect "GSLT TOKEN:"
set timeout 60
send "\r"
set timeout 60

EOF

chown $TF2_USER_NAME:$TF2_USER_NAME tf2server_expect_install.sh
chmod +x tf2server_expect_install.sh

# Change user to $TF2_USER_NAME and run the following commands as that user
# TODO: Fold the following commands into the expect script, if possible.
sudo -u tf2server -H sh -c "wget http://gameservermanagers.com/dl/tf2server"
sudo -u tf2server -H sh -c "chmod +x tf2server"
sudo -u tf2server -H sh -c "touch tf2server_install.log"
sudo -u tf2server -H sh -c "echo 'TF2SERVER_EXPECT LOG' >> tf2server_install.log"
sudo -u tf2server -H sh -c "./tf2server_expect_install.sh >>tf2server_install.log 2>&1"
sudo -u tf2server -H sh -c "echo 'TF2SERVER START LOG' >> tf2server_install.log"
sudo -u tf2server -H sh -c "$TF2_ROOT/tf2server start >>tf2server_install.log 2>&1"
sudo -u tf2server -H  sh -c "sed -i -E 's/(hostname )\".*\"/\1\"$TF2_LABEL\"/' $TF2_ROOT/serverfiles/tf/cfg/tf2-server.cfg"
sudo -u tf2server -H  sh -c "sed -i -E 's/(rcon_password )\".*\"/\1\"$RCON_PASS\"/' $TF2_ROOT/serverfiles/tf/cfg/tf2-server.cfg"

# TODO: Remove all intermediate installation files like tf2server_expect_install.sh

