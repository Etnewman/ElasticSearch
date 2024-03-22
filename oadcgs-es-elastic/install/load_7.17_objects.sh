#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Loads Dashboards, Visuals and other 7.12 saved objects
#          into Kibana
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: load_7.17_objects.sh
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

read -sp "User <$user> will be used to load 7.17 objects in elastic, please enter the password for $user: " -r passwd </dev/tty
echo

#Load 7.17 objects
curl --silent https://"$fileloc"/install/artifacts/savedObjects_7.17.ndjson >/tmp/savedObjects_7.17.ndjson
curl -k -XPOST -s -u "$user":"$passwd" "https://kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/tmp/savedObjects_7.17.ndjson
rm /tmp/savedObjects_7.17.ndjson

echo
echo
echo "Load 7.17 Objects Complete..."
echo
echo
#################################################################################
#
#			    Unclassified
#
#################################################################################
