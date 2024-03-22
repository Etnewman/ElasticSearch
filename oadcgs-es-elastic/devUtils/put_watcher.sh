#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Gets a watcher from Kibana and makes it human readable, as well as removes the first instance of "id" and "username"
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: put_watcher.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.1
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, date it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.1, CR-2021-OADCGS-035, Ethan Newman, 2022-04-21: Baseline, Sed Commands out first username and id, as well as human readable format.
#
# Site/System: Repo Server (ro01)
#
# Deficiency: N/A
#
# Use: This script is used to extract pipelines from elasticsearch
#
# Users: Elastic Pipeline Developers
#
# DAC Setting: 755 apache apache
# Required SELinux Security Context : httpd_sys_content_t
#
# Frequency: Utility Script, used as needed.
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
# Get pipeline from cmd line, if not provided ask for it
#
watcher=$1
if [ $# -lt 1 ] || [ "$1" == "-h" ] || [ "$1" == "-help" ]; then
  echo "put_watcher - Used to extract a specified watcher from elasticsearch and prepare it for baselining."
  echo " Usage: put_watcher.sh <watcher_id>"
  echo "Make sure your watcher file is in /tmp/"
  exit 0
fi

#
# Initilize variables
#

user=$SUDO_USER

read -sp "User <$user> will be used to put Watchers into from elastic, please enter the password for $user: " -r passwd </dev/tty
echo

#
# Pulls the pipeline from Kibana logstash and converts it to human readable format then appends -candidate
#

echo "putting watcher: $watcher"

curl --silent -XPUT -u "${user}":"${passwd}" https://elastic-node-1:9200/_watcher/watch/"${watcher}"?pretty -H 'Content-Type: application/json' -d@/tmp/"${watcher}"

#################################################################################
#
#			    Unclassified
#
#################################################################################
