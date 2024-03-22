#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Updates some logstash pipelines to be site based
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: load_sitebased_pipelines.sh
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

#
# Initilize variables
#

fileloc="satrepo/pulp/content/oadcgs/Library/custom/Elastic_Client/Elastic_Files"
user=$SUDO_USER

read -sp "User <$user> will be used to update logstash pipelines in elastic, please enter the password for $user: " -r passwd </dev/tty
echo

#
# This is an array of all pipeline names to be loaded
#
pipelines=(esp_linux_syslog esp_metricbeat)

#
# pull each pipeline from the satellite and load into kibana
#
for pipeline in "${pipelines[@]}"; do
  echo "putting pipeline: $pipeline "
  curl -k --silent https://"$fileloc"/install/pipelines/"${pipeline}" | sed -z 's/\n/\\n/g;;$ s/\\n$/\n/' >/tmp/"${pipeline}"

  loadpipe=$(curl -w 'return_code=%{http_code}\n' --silent -k -XPUT -u "${user}":"${passwd}" https://kibana/api/logstash/pipeline/"${pipeline}" -H 'kbn-xsrf:true' -H 'Content-Type: application/json' -d@/tmp/"${pipeline}")
  retcode=$(echo "$loadpipe" | awk -F 'return_code=' '{print $2}' | sed '/^$/d')
  if [ "$retcode" != "204" ]; then
    echo
    echo "*** ERROR LOADING PIPELINE: $pipeline *** "
    echo "Bad return code from curl: $retcode, Incorrect Password or Empty Pipeline."
    break
  fi

  rm /tmp/"${pipeline}"
done
#################################################################################
#
#			    Unclassified
#
#################################################################################
