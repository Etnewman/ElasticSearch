#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Loads beats monitoring dashboard into Kibana
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: load_beats_db.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, date it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Steve Truxal, 2021-03-24: Original Version
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

read -sp "User <$user> will be used to load dashboard into kibana, please enter the password for $user: " -r passwd </dev/tty
echo

#Load saved objects
object_name=beat_versions_db.ndjson

curl --silent https://"$fileloc"/install/artifacts/$object_name >/tmp/$object_name
curl -k -XPOST -s -u "$user":"$passwd" https://kibana/api/saved_objects/_import?overwrite=true -H "kbn-xsrf: true" --form file=@/tmp/$object_name
rm /tmp/$object_name

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
