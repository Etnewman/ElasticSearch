#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Updates Ingest pipelines in Elastic
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: update_logstash_pipelines.sh
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
# Use: This script is used to load ingest pipelines into elasticsearch
#
# Users: Elastic Installers
#
# DAC Setting: 755 apache apache
# Required SELinux Security Context : httpd_sys_content_t
#
# Frequency: During Elastic upgrade process
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
fileloc="satrepo/pulp/content/oadcgs/Library/custom/Elastic_Client/Elastic_Files"
user=$SUDO_USER

if [ -n "$1" ]; then
  # If version of pipelines is specified then it will be used
  ver=$1
else
  echo
  echo "Determining version..."
  if [ ! -f "/usr/share/elasticsearch/bin/elasticsearch" ]; then
    echo
    echo "*** ERROR *** "
    echo "This script must be run from an Elasticsearch node..."
    echo
    exit 1
  fi

  # Lets figure out the version to bootstrap based on version of installed elasticsearch
  ver=$(/usr/share/elasticsearch/bin/elasticsearch --version | /bin/cut -f2 -d' ' | /bin/sed 's/.$//')

  if [ -z "$ver" ]; then
    echo
    echo "*** ERROR *** "
    echo "Unable to determine elasticsearch version, this script must be run on an elasticsearch node..."
    echo
    exit 1
  fi
fi

#
# Load filebeat ingest pipelines into Elastic node
#
echo
echo "This script will load ingest pipelines for filebeat version: $ver"
echo

read -sp "User <$user> will be used to update ingest pipelines, enter password: " -r passwd </dev/tty

echo
echo
#
# This is an array of ingest pipelines to be added to elastic
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

for pipeline in "${pipelines[@]}"; do
  echo -n "updating pipeline: $pipeline - "
  curl -k --silent https://"$fileloc"/install/ingest_pipelines/"${pipeline}" >/tmp/"${pipeline}"
  sed -i ':a;$!{N;s/\n/ /;ba;}' /tmp/"${pipeline}"
  curl -k -XPUT -u "${user}":"${passwd}" https://elastic-node-1:9200/_ingest/pipeline/"${pipeline}" -H 'Content-Type: application/json' -d@/tmp/"${pipeline}"
  rm /tmp/"${pipeline}"
  echo
done

echo
echo "Script Complete"
echo
#################################################################################
#
#			    Unclassified
#
#################################################################################
