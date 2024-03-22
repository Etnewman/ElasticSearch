#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Used to install and setup the running of Curator for Archiving
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: installCurator.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Steve Truxal, 2021-03-15: Original Version
#
# Site/System: Repo Server (ro01)
#
# Deficiency: N/A
#
# Use: This script is used by the Elastic Installer
#
# Users: Elastic Installer sudoed to root user
#
# DAC Setting: 755 apache apache
# Required SELinux Security Context : httpd_sys_content_t
#
# Frequency: During Elastic Upgrade process
#
# Information Security Authorization
# ACC/A26 IA Approval: year-mm-dd, Name, ACC ISSE
#
# Lead System Engineering Authorization
# AF-DCGS LSE Approval: year-mm-dd, Name, AF-DCGS/AO
#
###########################################################################
#

# Let's make sure root is executing the script
if [[ $EUID -ne 0 ]]; then
  echo
  echo "***************** Install Failed **************************"
  echo "*                                                         *"
  echo "*  You must be root to install the curator                *"
  echo "*                                                         *"
  echo "***************** Install Failed **************************"
  echo
  exit 1
fi

#
# Initilize variables
#
fileloc="satrepo/pulp/content/oadcgs/Library/custom/Elastic_Client/Elastic_Files"

curatorDir="/etc/curator/"
curatorUser="curator"
curatorConfigTar="curatorConfig.tar"

user=$SUDO_USER

echo "."
read -sp "User <$user> will be used for interaction with elastic, please enter the password for $user: " -r passwd </dev/tty
echo

yum -y install python-cryptography
yum -y install elasticsearch-curator

echo "Setting up curator with our configs and script"
curl --silent https://"$fileloc"/install/artifacts/${curatorConfigTar} >/tmp/$curatorConfigTar

mkdir /etc/curator
tar xf /tmp/${curatorConfigTar} -C ${curatorDir}
chmod +x /etc/curator/runcurator.sh

# Create role for Curator User
rolename="curator_user"
echo "Createing role: $rolename"
curl -XPUT -s -u "${user}":"${passwd}" https://elastic-node-1:9200/_security/role/${rolename} -H "Content-Type: application/json" -d'
{
    "cluster" : [
      "create_snapshot",
      "cluster:admin/repository/put",
      "cluster:admin/repository/get",
      "cluster:admin/repository/verify",
      "monitor"
    ],
    "indices" : [
      {
        "names" : [
          "*"
        ],
        "privileges" : [
          "view_index_metadata",
          "monitor"
        ],
        "allow_restricted_indices" : true
      }
    ],
    "applications" : [ ],
    "run_as" : [ ],
    "metadata" : { },
    "transient_metadata" : {
      "enabled" : true
    }
}
'

# Generate random password for curator user
pass=$(tr -cd '[:alnum:]' </dev/urandom | fold -w15 | head -n1)

###### Bootstrap User for Curator
# First check to see if user already exists
returned_user=$(curl -k -u "$user":"$passwd" https://elastic-node-1:9200/_security/user/"$curatorUser")
if [ "$returned_user" == "{}" ]; then
  echo "User does not exist, create it"
  curl -k -u "${user}":"${passwd}" -XPOST -H 'Content-Type: application/json' "https://elastic-node-1:9200/_security/user/$curatorUser" -d "{\"password\":\"$pass\",\"roles\": \"curator_user\", \"full_name\" : \"Curator User\"}"
else
  echo "User exists, Just update password"
  curl -k -u "$user":"$passwd" -XPUT -H 'Content-Type: application/json' "https://elastic-node-1:9200/_security/user/$curatorUser/_password" -d "{\"password\":\"$pass\"}"
fi

# Encrypt the password and save it for use by Curator
cryptPass=$(python $curatorDir/Crypt.py -e "$pass")
echo "$curatorUser:$cryptPass" >$curatorDir/curator.dat

# Create cron.daily
echo -e "#!/bin/bash\n\n/etc/curator/runcurator.sh" >/etc/cron.daily/curator.cron
chmod 700 /etc/cron.daily/curator.cron

echo
#################################################################################
#
#			    Unclassified
#
#################################################################################
