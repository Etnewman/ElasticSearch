#!/bin/bash
#                           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Used to take snapshots of Elasticsearch indexes
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: runcurator.sh
#
# Location: "/etc/curator" directory one of the elastic nodes
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
# Use: This script is run automatically by cron.daily
#
# Users: cron.daily
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

# curator.dat will have user:encrypted password
# read user and store in elasticUser
# read encrypted password from file - store encrypted password in encryptedpw variable
# use crypt.py to decrypt password from file
#  elasticPassword=`python /etc/curator/Crypt.py -d $encryptedpw`

elasticUser=$(cut -d: -f1 /etc/curator/curator.dat)
encryptedPassword=$(cut -d: -f2 /etc/curator/curator.dat)
elasticPassword=$(python /etc/curator/Crypt.py -d "${encryptedPassword}")

# calculate dirname and location based on date-year
dirname="$(date +%b-%Y)"

# place variables in enviornment
export elasticUser
export elasticPassword
export dirname
export encryptedPassword

repos=$(curl -u "${elasticUser}":"${elasticPassword}" "https://elastic-node-1:9200/_cat/repositories?&h=id")

# loop through repos and determine if it already exists
needscreated=true
for repo in $repos; do
  if [ "$repo" == "$dirname" ]; then
    needscreated=false
  fi
done

# if repository doesn't exist then create it
if [ "$needscreated" == true ]; then

  # Create location file for command
  echo -e "{\n \"type\": \"fs\",\n \"settings\": {\n \"location\": \"$dirname\"\n }\n}" >/etc/curator/locfile

  echo "Creating Repo $dirname..."
  curl -X PUT -u "${elasticUser}":"${elasticPassword}" https://elastic-node-1:9200/_snapshot/"${dirname}"?pretty -H 'Content-Type: application/json' -d @/etc/curator/locfile
fi

# Run curator to take any needed snapshots
curator --config /etc/curator/configuration.yml /etc/curator/action.yml

echo
#################################################################################
#
#                           Unclassified
#
#################################################################################
