#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Used to remove Curator for Archiving
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: removeCurator.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Ethan Newman, 2022-04-27: Original Version
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
  echo "*  You must be root to remove the curator                *"
  echo "*                                                         *"
  echo "***************** Install Failed **************************"
  echo
  exit 1
fi

#
# Initilize variables
#

curatorDir="/etc/curator/"
curatorUser="curator"
curatorRole="curator_user"

user=$SUDO_USER
ES_HOST="elastic-node-1"
ES_PORT="9200"

echo "."
read -sp "User <$user> will be used for interaction with elastic, please enter the password for $user: " -r passwd </dev/tty
echo

# Ensure password provided is valid
pwcheck=$(curl -k --silent -u "${user}":"${passwd}" "https://${ES_HOST}:${ES_PORT}/_cluster/health" --write-out '%{http_code}')
retval=${pwcheck: -3}
if [[ $retval != 200 ]]; then
  echo
  echo "Unable to communcate with Elasticsearch. Did you enter your password correctly?"
  echo "Script aborted, please try again."
  echo
  exit
fi

#yum -y install python-cryptography
yum -y remove elasticsearch-curator

# Delete Curator Directory
rm -rf $curatorDir

# Delete Curator User
echo "Deleting user: $curatorUser"
curl -XDELETE -s -u "${user}":"${passwd}" https://elastic-node-1:9200/_security/user/$curatorUser

# Delete role for Curator User
echo "Deleting role: $curatorRole"
curl -XDELETE -s -u "${user}":"${passwd}" https://elastic-node-1:9200/_security/role/$curatorRole

# Delete cron.daily
rm /etc/cron.daily/curator.cron

echo
echo
echo "Curator Removed."
echo
echo
#################################################################################
#
#			    Unclassified
#
#################################################################################
