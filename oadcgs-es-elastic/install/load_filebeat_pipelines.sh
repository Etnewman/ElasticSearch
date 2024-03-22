#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Installs filebeat ingest pipelines into Elastic
#
# Tracking #: CR-2020-OADCGS-086
#
# File name: load_filebeat_pipelines.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, date it was revised,
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

elasticpw="elastic"

#
# Load ingest pipelines for all modules in the "modules" string
#
modules="auditd,iptables,logstash,netflow,system,elasticsearch"
echo
echo
echo "Adding ingest pipelines for modules: ${modules}"
cd /etc/filebeat || exit
filebeat setup --pipelines --modules ${modules} -E output.logstash.enabled=false -E output.elasticsearch.hosts=["https://elastic-node-1:9200"] -E output.elasticsearch.username=elastic -E output.elasticsearch.password="$elasticpw" -E output.elasticsearch.ssl.certificate_authorities="/etc/pki/tls/certs/ca-bundle.crt"
echo
echo
#################################################################################
#
#			    Unclassified
#
#################################################################################
