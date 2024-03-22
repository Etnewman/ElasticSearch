#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Verify Elasticsearch Archive Directory exists
#
# Tracking #: CR-2020-OADCGS-086
#
# File name: verifyArchiveDir.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2020-OADCGS-086, Steve Truxal, 2020-04-09: Original Version
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
# Frequency: During Elasticsearch initial installation
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
serviceAcct="$(hostname | cut -c 2,3)_elastic.svc"
archiveDir="elasticArchive"

####################
# Main begins here #
####################
echo
echo "This script will ensure the ${archiveDir} directory exists"
echo

# lets make sure the data directory for all elastic nodes is in place
datadir_exists=$(runuser -l "${serviceAcct}" -c "if [ -d /ELK-nfs/${archiveDir} ]; then echo true; fi")

if [ "$datadir_exists" != "true" ]; then
  #data directory does not exist so create it
  runuser -l "${serviceAcct}" -c "mkdir /ELK-nfs/${archiveDir}"
  echo "Created ${archiveDir} directory."
else
  echo "${archiveDir} directory already exits."
fi

echo
echo "Elastic verifyArchiveDir finished"
echo
#################################################################################
#
#			    Unclassified
#
#################################################################################
