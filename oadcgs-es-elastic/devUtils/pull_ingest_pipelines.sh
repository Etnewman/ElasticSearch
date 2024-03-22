#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Loads ingest pipelines to elastic node, then pulls nodes down into ingest_pipelines directory.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: pull_ingest_pipelines.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.1
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, date it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.1, CR-2021-OADCGS-035, Robert Williamson, 2022-06-15: Original Version
#
# Site/System: Repo Server (ro01)
#
# Deficiency: N/A
#
# Use: This script is used to pull ingest pipelines from elasticsearch
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
# Initialize variables
#
user=$SUDO_USER

ver=$(filebeat version | cut -d " " -f 3)

if [ -z "$ver" ]; then
  echo
  echo "*** ERROR *** "
  echo "Unable to determine filebeat version, the Filebeat to obtain ingest pipelines for must be loaded..."
  echo
  exit 1
fi
#
# Load filebeat ingest pipelines into Elastic node
#
echo
echo "This script will load ingest pipelines for filebeat version: $ver"
echo

read -sp "User <$user> will be used to load and pull ingest pipelines, enter password: " -r passwd </dev/tty

echo

modules="auditd,iptables,logstash,system,elasticsearch"
echo
echo
echo "Adding ingest pipelines for modules: ${modules}"
cd /etc/filebeat || exit
# The --enable-all-filesets flag needs to be re-evalauted for future updates from Elastic
filebeat setup --pipelines --enable-all-filesets -E output.logstash.enabled=false -E output.elasticsearch.hosts=["https://elastic-node-1:9200"] -E output.elasticsearch.username="$user" -E output.elasticsearch.password="$passwd" -E output.elasticsearch.ssl.certificate_authorities="/etc/pki/tls/certs/ca-bundle.crt"
echo
echo

#
# This is an array of pipelines to be pulled
#
pipelines=(
  filebeat-"${ver}"-auditd-log-pipeline
  filebeat-"${ver}"-elasticsearch-audit-pipeline
  filebeat-"${ver}"-elasticsearch-deprecation-pipeline
  filebeat-"${ver}"-elasticsearch-gc-pipeline
  filebeat-"${ver}"-elasticsearch-server-pipeline
  filebeat-"${ver}"-elasticsearch-slowlog-pipeline
  filebeat-"${ver}"-iptables-log-pipeline
  filebeat-"${ver}"-logstash-log-pipeline
  filebeat-"${ver}"-logstash-slowlog-pipeline
  filebeat-"${ver}"-system-auth-pipeline
  filebeat-"${ver}"-system-syslog-pipeline
  filebeat-"${ver}"-elasticsearch-audit-pipeline-json
  filebeat-"${ver}"-elasticsearch-deprecation-pipeline-json
  filebeat-"${ver}"-elasticsearch-server-pipeline-json
  filebeat-"${ver}"-elasticsearch-slowlog-pipeline-json
  filebeat-"${ver}"-logstash-log-pipeline-json
  filebeat-"${ver}"-logstash-slowlog-pipeline-json
  filebeat-"${ver}"-elasticsearch-audit-pipeline-plaintext
  filebeat-"${ver}"-elasticsearch-deprecation-pipeline-plaintext
  filebeat-"${ver}"-elasticsearch-server-pipeline-plaintext
  filebeat-"${ver}"-elasticsearch-slowlog-pipeline-plaintext
  filebeat-"${ver}"-logstash-log-pipeline-plaintext
  filebeat-"${ver}"-logstash-slowlog-pipeline-plaintext
  filebeat-"${ver}"-kibana-audit-pipeline
  filebeat-"${ver}"-kibana-audit-pipeline-json
  filebeat-"${ver}"-kibana-log-pipeline
  filebeat-"${ver}"-kibana-log-pipeline-7
  filebeat-"${ver}"-kibana-log-pipeline-ecs
  winlogbeat-"${ver}"-sysmon
  winlogbeat-"${ver}"-security
  winlogbeat-"${ver}"-routing
  winlogbeat-"${ver}"-powershell
  winlogbeat-"${ver}"-powershell_operational

)
#
# check that ingest_pipelines directory exist
#
dir="./ingest_pipelines"
if [ ! -d "$dir" ]; then
  echo "ingest_pipelines directory does not exist, creating it. . ."
  mkdir ingest_pipelines
fi
#
# pull all pipelines
#
IFS='-'
for pipeline in "${pipelines[@]}"; do
  echo "pulling pipeline: $pipeline"
  read -r -a newver <<<"$pipeline"
  if [ "${newver[1]}" = "$ver" ]; then
    curl -k --silent -u "${user}":"${passwd}" https://elastic-node-1:9200/_ingest/pipeline/"${pipeline}"?pretty >./ingest_pipelines/"${pipeline}"
    sed -i -e '2d;$d' ./ingest_pipelines/"${pipeline}"
    echo "$pipeline succcessfully pulled"
  else
    echo "ERROR: current filebeat version does not match version of $pipeline"
  fi
done

#################################################################################
#
#			    Unclassified
#
#################################################################################
