General scripts used for initialization of AWS resources such as EC2 instances.

tf2_init_aws_ubuntu.sh

This is an initialization script that uses the Linux Game Server Managers script (https://gameservermanagers.com/) to spin up Team Fortress 2 dedicated server software on AWS EC2 instances. It is an automation of the instructions decribed here: http://www.riseoftheidiot.com/team-fortress-2-server.html. Add your details to the config constant at the beginning of this script then upload this script in the "Advanced Details" setion of the "Configure Instance" tab in the "Launch Instance" wizard for EC2.

Other things to note:
* This script is configured to place the TF2 server on a EBS device that has been mounted to the EC2 instance, the file path of the EBS device is specified as a config constant. The default value is '/dev/xvdb' which is the default EBS device location on Ubuntu.
* Currently the script has only been tested for Ubuntu only. Additional customization is needed to make it work with other distros