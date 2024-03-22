#!/bin/bash
#                           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Creates new Baseline space and moves Default space to
#          Default Deprecated space
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: update_default_space.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, date it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Steve Truxal, 2021-03-22: Original Version
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

# Get the user that executed the script
username=$SUDO_USER
site_num=$(hostname | cut -c 2-3)

# Check to see if this is WCH Cluster
if [ "${site_num,,}" == "0a" ]; then
  kibana="kibana-wch"
else
  kibana="kibana"
fi

if [ -z "$username" ] || [ "$username" == "root" ]; then
  echo "ERROR: Script needs to be run from 'sudo su' not 'sudo su -'.  And don't run su twice (SUDO_USER needs to contain your username)."
  exit 1
fi

echo "."
read -sp "User <$username> will be used to remove and load objects in ElasticSearch. Please enter the password for $username: " -r passwd </dev/tty
echo

# Ensure the password provided is valid
space_list=$(curl -k --silent -u "${username}:${passwd}" "https://${kibana}/api/spaces/space" --write-out '%{http_code}')
retval=${space_list: -3}
if [[ $retval != 200 ]]; then
  echo "Unable to communicate with Kibana. Did you enter your password correctly?"
  echo "Script aborted, please try again."
  echo
  echo "Usage: "
  echo "   For Elastic upgrades (prompts for password): "
  echo "       curl -s -k https://satrepo/pulp/content/oadcgs/Library/custom/Elastic_Client/Elastic_Files/install/update_default_space.sh | bash "
  echo
  exit 1
fi

#Create Default-Deprecated Space
if ! echo "$space_list" | grep -q "default-deprecated"; then
  echo "Creating space: Default-Deprecated"
  curl -k -XPOST -s -u "$username":"$passwd" https://${kibana}/api/spaces/space -H "kbn-xsrf:true" -H "Content-Type: application/json" -d'
      {
        "id":"default-deprecated",
        "name":"Default-Deprecated",
        "description":"Copy of previous version of Default space",
        "initials":"Dd",
        "color":"#454B1B",
        "disabledFeatures":[]
      }'
  echo
else
  echo "Default-Deprecated space already exists, not creating."
  echo
fi

#Create Baseline Space
if ! echo "$space_list" | grep -q "baseline"; then
  echo "Creating space: Baseline"
  curl -k -XPOST -s -u "$username":"$passwd" https://${kibana}/api/spaces/space -H "kbn-xsrf:true" -H "Content-Type: application/json" -d'
      {
        "id":"baseline",
        "name":"Baseline",
        "description":"Copy of previous version of Default space",
        "initials":"Bl",
        "color":"#00FFFF",
        "disabledFeatures":[]
      }'
  echo
else
  echo "Baseline already exists, not creating."
  echo
fi

# Export ndjson from Default Space
curl -k --silent -X POST -u "${username}:${passwd}" "https://${kibana}/api/saved_objects/_export" -H 'kbn-xsrf: true' -H 'Content-Type: application/json' -d '
     {
       "type": "dashboard",
       "includeReferencesDeep": true,
       "excludeExportDetails": true
     }' >/tmp/defdep.ndjson

# Import ndjson to Default-Deprecated
curl -k --silent -X POST -u "${username}:${passwd}" "https://${kibana}/s/default-deprecated/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/tmp/defdep.ndjson >/dev/null

echo "Please wait removing Data Views and Dashboards from default space"

#
# Remove Data Views from Default space
data_views=$(curl -k --silent -u "${username}:${passwd}" "https://${kibana}/api/data_views" | tr "," "\n" | grep \"id\": | tr -d '{["' | sed 's/^data_view://' | cut -f2 -d: | tr '\n' ' ')

for data_view in ${data_views}; do
  curl -k --silent -X DELETE -u "${username}:${passwd}" "https://${kibana}/api/data_views/data_view/$data_view" -H 'kbn-xsrf: true' >/dev/null
done

#
# Remove Dashboards from Default space
dashboards=$(curl -sk --silent -u "${username}:${passwd}" "https://${kibana}/api/saved_objects/_find?per_page=1000&fields=id&type=dashboard" | tr "," "\n" | grep -A 1 \"type\":\"dashboard\" | grep \"id\": | cut -f2 -d: | tr '\n' ' ' | tr -d ']}"')

for dashboard in ${dashboards}; do
  curl -sk -X DELETE --silent -u "${username}:${passwd}" "https://${kibana}/api/saved_objects/dashboard/$dashboard" -H 'kbn-xsrf: true' >/dev/null
done

rm /tmp/defdep.ndjson
