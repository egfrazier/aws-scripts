#!/bin/bash

# General config constants
SERVER_TYPE='primary'
EBS_DEVICE=/dev/xvdb
HTTPD_ROOT=/var/www/html
SITE_SYS_USER='ec2-user'

# WP General Info
WP_URL=''
WP_TITLE='""' # Double quotes are needed so that WP-CLI does not interpret this string as multiple values.

# WP DB Credentials (an empty database should alreay exist on the RDS instance)
WP_DB_HOST=''
WP_DB_USER=''
WP_DB_PASS=''
WP_DB_NAME=''
WP_DB_PREFIX=''

# WP admin credentials
WP_ADMIN_NAME=''
WP_ADMIN_PASS=''
WP_ADMIN_EMAIL=''



# Uninstall default Apache and PHP and remove with 2.4 and 7.0, respectively.
# Also install supporting PHP modules and the expect command
yum remove -y httpd* php*
yum install -y httpd24 php70 php70-mysqlnd mysql php70-gd expect
sed -i '151 s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf # Find a more portable way to do this.
service httpd start

# Tests whether or not the EBS has a filesystem. If true, create a EXT4 filesystem
# on that block storage and then mount to a subdirectory in the httpd root
# directory.
echo "Checking $EBS_DEVICE for exising filesystem..."
if [[ $(sudo file -s $EBS_DEVICE | grep data) ]] 
then 
	echo 'No filesystem detected on $EBS. Setting up an EXT4 filesystem and mounting to Apache document root.'
	sudo mkfs -t ext4 $EBS_DEVICE
	sudo mount $EBS_DEVICE $HTTPD_ROOT	 
else 
	echo 'filesystem already exists'
fi

# Installing WP-CLI
cd $HTTPD_ROOT/..
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/sbin/wp

# Install core WordPress
chown $SITE_SYS_USER:$SITE_SYS_USER -R /var/www/html
cd $HTTPD_ROOT
sudo -u $SITE_SYS_USER -H sh -c "wp core download"
sudo -u $SITE_SYS_USER -H sh -c "wp config create --dbname=$WP_DB_NAME --dbuser=$WP_DB_USER --dbpass=$WP_DB_PASS --dbhost=$WP_DB_HOST --dbprefix=$WP_DB_PREFIX"
sudo -u $SITE_SYS_USER -H sh -c "wp core install --url=$WP_URL --title=$WP_TITLE --admin_user=$WP_ADMIN_NAME --admin_password=$WP_ADMIN_PASS --admin_email=$WP_ADMIN_EMAIL --skip-email"


# Install AWS plugin
sudo -u $SITE_SYS_USER -H sh -c "wp plugin install https://downloads.wordpress.org/plugin/amazon-web-services.1.0.3.zip --activate"

# Install AWS S3 Offload Plugin
sudo -u $SITE_SYS_USER -H sh -c "wp plugin install https://downloads.wordpress.org/plugin/amazon-s3-and-cloudfront.1.2.zip --activate"

# Install WP Crontrol Plugin (TODO: configure settings to support S3 Offload plugin)
sudo -u $SITE_SYS_USER -H sh -c "wp plugin install https://downloads.wordpress.org/plugin/wp-crontrol.1.5.zip"

chown apache:apache -R $HTTPD_ROOT

# Set pretty permalinks
sudo -u $SITE_SYS_USER -H sh -c "wp rewrite structure '/%year%/%monthnum%/%postname%/'"
