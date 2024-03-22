#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Convenience script to add a pipeline supplied by an external source.
#
# Tracking #: CR-2020-OADCGS-086
#
# File name: add_pipeline.sh
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
# Use Create Logstash Pipeline API
#
echo
echo
read -p "Enter Username to add pipeline(Must be a Kibana Admin): " -r user </dev/tty
read -p "Enter name of pipeline being added: " -r pipeline </dev/tty
read -p "Enter filename containing pipeline to add(include path): " -r pipefile </dev/tty

curl -k -XPUT -u "${user}" https://kibana/api/logstash/pipeline/"${pipeline}" -H 'kbn-xsrf:true' -H 'Content-Type: application/json' -d@"${pipefile}"
#################################################################################
#
#			    Unclassified
#
#################################################################################
