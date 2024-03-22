#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Change index setting of certain indexes to support searchable
#          snapshots
#
# Tracking #: CR-2023-OADCGS-23285
#
# File name: setupSearchableSnapshots.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, date it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.0, CR-2023-OADCGS-23285, Tian Zhao, 10/26/2023: Original Version
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
ES_HOST="elastic-node-1"
ES_PORT="9200"

indexArr=(
  dcgs-audits_syslog
  dcgs-db
  dcgs-hbss_epo
  dcgs-syslog
  dcgs-vsphere
  winlogbeat
)

echo
read -sp "User <$user> will be used to load the ILM Policy into elastic, please enter the password for $user: " -r passwd </dev/tty

# Ensure password provided is valid
pwcheck=$(curl -k --silent -u "${user}":"${passwd}" "https://${ES_HOST}:${ES_PORT}/_cluster/health" --write-out '%{http_code}')
retval=${pwcheck: -3}
if [[ $retval != 200 ]]; then
  echo
  echo "Unable to communicate with Elasticsearch. Did you enter your password correctly?"
  echo "Script aborted, please try again."
  echo
  exit
fi

echo
echo "Updating index settings..."
echo

for key in "${indexArr[@]}"; do
  indices_list=("$(curl --silent -k -XGET -u "${user}":"${passwd}" "https://${ES_HOST}:${ES_PORT}/_cat/indices/${key}*?h=index")")

  # shellcheck disable=SC2206
  # shellcheck disable=SC2128
  indexes=($indices_list)

  for ((i = 0; i < ${#indexes[@]}; i++)); do
    index=${indexes[$i]}
    if [[ $index =~ dcgs-audits_syslog* ]]; then
      curl -XPUT -s -u "${user}":"${passwd}" https://${ES_HOST}:${ES_PORT}/"${index}"/_settings -H "Content-Type: application/json" -d'
      {
        "index.lifecycle.name": "dcgs_audits_syslog_policy"
      }
      '
    elif [[ $index =~ dcgs-db* ]]; then
      curl -XPUT -s -u "${user}":"${passwd}" https://${ES_HOST}:${ES_PORT}/"${index}"/_settings -H "Content-Type: application/json" -d'
      {
        "index.lifecycle.name": "dcgs_db_policy"
      }
      '
    elif [[ $index =~ dcgs-hbss_epo* ]]; then
      curl -XPUT -s -u "${user}":"${passwd}" https://${ES_HOST}:${ES_PORT}/"${index}"/_settings -H "Content-Type: application/json" -d'
      {
        "index.lifecycle.name": "dcgs_hbss_epo_policy"
      }
      '
    elif [[ $index =~ dcgs-syslog* ]]; then
      curl -XPUT -s -u "${user}":"${passwd}" https://${ES_HOST}:${ES_PORT}/"${index}"/_settings -H "Content-Type: application/json" -d'
      {
        "index.lifecycle.name": "dcgs_syslog_policy"
      }
      '
    elif [[ $index =~ dcgs-vsphere* ]]; then
      curl -XPUT -s -u "${user}":"${passwd}" https://${ES_HOST}:${ES_PORT}/"${index}"/_settings -H "Content-Type: application/json" -d'
      {
        "index.lifecycle.name": "dcgs_vsphere_policy"
      }
      '
    elif [[ $index =~ winlogbeat* ]]; then
      curl -XPUT -s -u "${user}":"${passwd}" https://${ES_HOST}:${ES_PORT}/"${index}"/_settings -H "Content-Type: application/json" -d'
      {
        "index.lifecycle.name": "dcgs_winlogbeat_policy"
      }
      '
    fi
  done
done

echo
echo
echo "Index settings changed."
echo
echo

#################################################################################
#
#			    Unclassified
#
#################################################################################
