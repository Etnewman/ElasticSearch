#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Used to verify and load SLM Policies
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: load_SLM_Policy.sh
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
  echo "*  You must be root to install the curator                *"
  echo "*                                                         *"
  echo "***************** Install Failed **************************"
  echo
  exit 1
fi

#
# Initilize variables
#
globalState="false"

user=$SUDO_USER

echo "."
read -sp "User <$user> will be used for interaction with elastic, please enter the password for $user: " -r passwd </dev/tty
echo

# Indicies used for the SLM Polcies
indexes=(dcgs-syslog winlogbeat dcgs-hbss_epo dcgs-db dcgs-vsphere .siem-signals dcgs-audits_syslog)

# Cron timing for policies
min=0
hour=1

for index in "${indexes[@]}"; do

  # Cron time created for each policy
  cron="0 $min $hour * * ?"

  # Remove the prefix to create the snapshot repo
  myRepo="${index//dcgs-/}"
  myPolicy="${index}"

  if [ "$index" == ".siem-signals" ]; then
    globalState="true"
    myRepo="system"
    myPolicy="dcgs-system"
  fi

  if [ "$myRepo" == "db" ]; then
    myRepo="database"
  fi

  # Verify that the Snapshot Repository Exists
  echo "Checking for Snapshot Repo: $myRepo"

  verify_repo=$(curl -w 'return_code=%{http_code}\n' --silent -k -XGET -u "${user}":"${passwd}" https://elastic-node-1:9200/_snapshot/"${myRepo}")
  retcode_repo=$(echo "$verify_repo" | awk -F 'return_code=' '{print $2}' | sed '/^$/d')

  # If the user failed authentication, exit
  if [ "$retcode_repo" == "401" ]; then
    echo "*** Authentication with Elasticsearch failed for user: %{$user} ***"
    echo
    break
  fi

  # If the Snapshot Repo does not exist, create it
  if [ "$retcode_repo" == "404" ]; then
    echo "*** SNAPSHOT REPO DOES NOT EXIST, CREATING SNAPSHOT REPO: $myRepo ***"
    echo
    curl -XPUT -s -u "${user}":"${passwd}" https://elastic-node-1:9200/_snapshot/"${myRepo}" -H "Content-Type: application/json" -d'
{
  "type": "fs",
  "settings": {
    "location": "'"$myRepo"'"
  }
}
'
  fi

  # Verify that SLM Exists
  echo
  echo "Checking for SLM: $myPolicy"

  verify_slm=$(curl -w 'return_code=%{http_code}\n' --silent -k -XGET -u "${user}":"${passwd}" https://elastic-node-1:9200/_slm/policy/"${myPolicy}")
  retcode_slm=$(echo "$verify_slm" | awk -F 'return_code=' '{print $2}' | sed '/^$/d')
  echo

  # Create the SLM Policy if it doesn't exist
  if [ "$retcode_slm" == "404" ]; then
    echo "*** SLM DOES NOT EXIST, Creating SLM: $myPolicy ***"
    flag="*** POLICY CREATED ***"
    echo

  # Update the SLM Policy if it does exist
  else
    echo "*** SLM ALREADY EXISTS, Updating SLM: $myPolicy ***"
    flag="*** POLICY UPDATED ***"
    echo
  fi

  curl -XPUT -s -u "${user}":"${passwd}" https://elastic-node-1:9200/_slm/policy/"${myPolicy}" -H "Content-Type: application/json" -d'
{
    "schedule": "'"$cron"'",
    "name": "'"<$myPolicy-snap-{now/d}>"'",
    "repository": "'"$myRepo"'",
    "config": {
      "indices": ["'"$index*"'", "'"-partial*"'", "'"-restored*"'", "'"-*-wch*"'", "'"-*-ech*"'"],
      "ignore_unavailable": false,
      "include_global_state": "'"$globalState"'"
    },
    "retention": {
      "expire_after": "1825d"
    }
}
'
  echo
  echo "$flag"
  echo

  # Increment Cron timing by 30 minutes
  min=$((min + 30))
  if [ $min -eq 60 ]; then
    min=0
    hour=$((hour + 1))
  fi

done

echo
#################################################################################
#
#			    Unclassified
#
#################################################################################
