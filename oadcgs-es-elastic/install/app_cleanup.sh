#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Deletes documents in the dcgs-current-healthdata-iaas-ent index
#          so the new esp_filebeat-logstash can take effect
#
# Tracking #:
#
# File name: app_cleanup.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, Corey Maher, 2023-10-24: Original Version
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
# Frequency: When the newest esp_filebeat-logstash is  loaded
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
# Initialize Variables
#

user=$SUDO_USER

read -sp "User <$user> will be used to delete documents, please enter password for $user: " -r passwd </dev/tty
echo

curl -k -u "${user}":"${passwd}" -XPOST "https://elastic-node-1:9200/dcgs-current-healthdata-iaas-ent/_delete_by_query" -H "Content-Type: application/json" -d '
{
  "query": {
    "terms": {
      "metadata.DocSubtype": ["app-overall", "group", "datacollector"]
    }
  }
}
'
