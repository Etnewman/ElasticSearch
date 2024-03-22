#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Loads filebeat ingest pipelines for current version
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: update_filebeat_pipelines.sh
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

user=$SUDO_USER

ver=$(filebeat version | cut -d " " -f 3)
echo
echo "This script will load ingest pipelines for filebeat version: $ver"
echo
read -sp "User <$user> will be used to store templates in elastic, please enter the password for $user: " -r passwd </dev/tty
echo

#
# Load ingest pipelines for all modules in the "modules" string
#
modules="auditd,iptables,logstash,system,elasticsearch"
echo
echo
echo "Adding ingest pipelines for modules: ${modules}"
cd /etc/filebeat || exit
filebeat setup --pipelines --modules ${modules} -E output.logstash.enabled=false -E output.elasticsearch.hosts=["https://elastic-node-1:9200"] -E output.elasticsearch.username="$user" -E output.elasticsearch.password="$passwd" -E output.elasticsearch.ssl.certificate_authorities="/etc/pki/tls/certs/ca-bundle.crt"
echo
echo
#################################################################################
#
#			    Unclassified
#
#################################################################################
