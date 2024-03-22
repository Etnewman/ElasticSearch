#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Loads spaces and saved objects into Elastic
#
# Tracking #: CR-2020-OADCGS-086
#
# File name: load_objects.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, date it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2020-OADCGS-086, Steve Truxal, 2020-08-31: Original Version
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
# Frequency: During Elasticsearch initial install
#
# Information Security Authorization
# ACC/A26 IA Approval: year-mm-dd, Name, ACC ISSE
#
# Lead System Engineering Authorization
# AF-DCGS LSE Approval: year-mm-dd, Name, AF-DCGS/AO
#
###########################################################################
#

#
# Initilize variables
#
fileloc="satrepo/pulp/content/oadcgs/Library/custom/Elastic_Client/Elastic_Files"
user=$SUDO_USER
site_num=$(hostname | cut -c 2-3)

# Check to see if this is WCH Cluster
if [ "${site_num,,}" == "0a" ]; then
  kibana="kibana-wch"
else
  kibana="kibana"
fi

echo "Loading objects into ${kibana}"

read -sp "User <$user> will be used to load objects in elastic, please enter the password for $user: " -r passwd </dev/tty
echo

# Ensure password provided is valid
pwcheck=$(curl -k --silent -u "${user}":"${passwd}" "https://${kibana}/api/spaces/space" --write-out '%{http_code}')

retval=${pwcheck: -3}
if [[ $retval != 200 ]]; then
  echo
  echo "Unable to communicate with Kibana. Did you enter your password correctly?"
  echo "Script aborted, please try again."
  echo
  exit
fi

if [ -n "$1" ] && [ "$1" == "install" ]; then
  # Initial setup spaces will be created
  echo "Initial setup, creating spaces..."

  curl -k -XPOST -s -u "${user}":"${passwd}" https://${kibana}/api/spaces/space -H "kbn-xsrf:true" -H "Content-Type: application/json" -d'
  {
      "id":"cyber-analytics",
      "name":"Cyber Analytics",
      "initials":"Cy",
      "disabledFeatures":[],
      "description":"This space is for the Cyber Analytics team"
  }
  '

  curl -k -XPOST -s -u "${user}":"${passwd}" https://${kibana}/api/spaces/space -H "kbn-xsrf:true" -H "Content-Type: application/json" -d'
  {
      "id":"sandbox",
      "name":"Sandbox",
      "description":"The is a space to learn and explore in",
      "initials":"SB","color":"#6092C0","disabledFeatures":[]
  }
  '
fi

ndjsonfiles=(
  Baseline-Space-Objects.ndjson
  dcgs-ashes.ndjson
  dcgs-ecp.ndjson
  dcgs-guardian.ndjson
  dcgs-gxpxplorer.ndjson
  dcgs-maas.ndjson
  dcgs-render.ndjson
  dcgs-soaesb.ndjson
  dcgs-socetgxp.ndjson
  dcgs-unicorn.ndjson
)

#Load saved objects for default space

for ndjsonfile in "${ndjsonfiles[@]}"; do

  echo -n "loading  $ndjsonfile..."

  curl -k --silent https://"$fileloc"/install/artifacts/"$ndjsonfile" >/tmp/"$ndjsonfile"
  curl -k -XPOST -s -u "$user":"$passwd" "https://${kibana}/s/baseline/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/tmp/"$ndjsonfile" >/dev/null
  echo
  rm /tmp/"$ndjsonfile"

done

echo
echo
echo "Load Objects Complete..."
echo
echo
#################################################################################
#
#			    Unclassified
#
#################################################################################
