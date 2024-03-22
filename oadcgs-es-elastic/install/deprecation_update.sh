#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Activates the ACAS portion of the Elastic Data Collector.
#
# Tracking #: CR-2020-OADCGS-086
#
# File name: deprecation_fix_8-6-2.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2020-OADCGS-086, Steve Truxal, 2020-06-29: Original Version
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
# Frequency: When adding a pipeline to Kibana is necessary
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

username=$SUDO_USER
read -sp "User <$username> will be used to fix various deprecation issues, please enter password for $username: " -r passwd </dev/tty
ES_HOST="elastic-node-1"
ES_PORT="9200"

# Removes persistent cluster settings that are deprecated

curl -XPUT -s -u "${username}":"${passwd}" https://${ES_HOST}:${ES_PORT}/_cluster/settings -H "kbn-xsrf: reporting" -H "Content-Type: application/json" -d'
{
  "persistent": {
    "xpack": {
      "monitoring": {
        "elasticsearch": {
          "collection": {
            "enabled": null
          }
        },
        "migration": {
          "decommission_alerts": null
        },
        "collection": {
          "enabled": null
        }
      }
    }
  }
}'
