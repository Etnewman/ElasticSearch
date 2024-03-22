#!/bin/bash
#                           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Loads the default "Cross Cluster Replication(CCR) into
#          Elastic
#
# Tracking #: CR-2020-OADCGS-086
#
# File name: load_CCR.sh
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

user=$SUDO_USER
snum=$(hostname | cut -c 2-3)
ES_PORT="9200"
ES_HOST="elastic-node-1"
TP_PORT="9300"
dnsDom=$(hostname -d | cut -f2,3 -d".")

# Function: setupRC
# Parameters: None
# Desc: Setup Remote Cluster
function setupRC() {
  remote_cluster=$(curl -k --silent -u "${user}":"${passwd}" --write-out '%{http_code}' -XPUT "https://${ES_HOST}:${ES_PORT}/_cluster/settings" -H 'Content-Type: application/json' -d '
{
  "persistent": {
    "cluster": {
      "remote": {
        "'"${suffix^^}_Cluster"'" : {
          "skip_unavailable": false,
          "mode": "sniff",
          "proxy_address": null,
          "proxy_socket_connections": null,
          "server_name": null,
          "seeds": [
            "'"elastic-node-7.${suffix}.${dnsDom}:${TP_PORT}"'",
            "'"elastic-node-8.${suffix}.${dnsDom}:${TP_PORT}"'",
            "'"elastic-node-9.${suffix}.${dnsDom}:${TP_PORT}"'"
          ],
          "node_connections": 3
        }
      }
    }
  }
}
')

  status=${remote_cluster: -3}
  if [ "$status" != 200 ]; then
    echo
    echo "*** ERROR *** "
    echo "Unable to set up remote cluster."
    echo "Incorrect password, privilege, or connection."
    echo "Try password again or Contact an Elastic SME"
    echo
    exit 1
  fi

  echo "Added Remote Cluster: ${suffix^^}_Cluster"
}

# Function: timeseriesCCR
# Parameters: None
# Desc: Setup auto_follow Cross Cluster Replication (CCR)
function timeseriesCCR() {

  #
  # This is an array of all time series indexes
  #
  timeseries=(
    dcgs-device
    dcgs-db
    dcgs-filebeat
    dcgs-audits_syslog-iaas-ent
    dcgs-syslog-iaas-ent
    dcgs-hbss_epo-iaas-ent
    dcgs-hbss-metrics-iaas-ent
    dcgs-healthdata-iaas-ent
    dcgs-vsphere-iaas-ent
    dcgs-iptables-iaas-ent
    filebeat
    heartbeat
    winlogbeat
    metricbeat
    .monitoring
  )

  for ts in "${timeseries[@]}"; do
    if [[ ${ts} == dcgs* ]]; then
      auto_follow_pattern_name=$(echo "${ts}" | cut -f2 -d"-" | cut -f1 -d"_")
    else
      auto_follow_pattern_name="${ts}"
    fi

    if [[ "${ts}" == \.* ]]; then
      auto_follow_pattern_name="${ts:1}"
      ts=".ds-.${auto_follow_pattern_name}"
    fi

    curl --silent -k -u "${user}":"${passwd}" -XPUT "https://${ES_HOST}:${ES_PORT}/_ccr/auto_follow/${auto_follow_pattern_name^}?pretty" -H 'Content-Type: application/json' -d'
    {
      "remote_cluster" : "'"${suffix^^}_Cluster"'",
      "leader_index_patterns" :
      [
        "'"${ts}*"'"
      ],
      "leader_index_exclusion_patterns" :
      [
        "'"${ts}*-${sname}*"'"
      ],
      "follow_index_pattern" : "'"{{leader_index}}-${suffix}"'"
    }
    ' >/dev/null
    #
    # Rollover remote indices to start following
    #
    if [[ "${ts}" == \.* ]]; then
      #
      # Get list of data streams
      data_streams=("$(curl --silent -k -u "${user}":"${passwd}" -XGET "https://${ES_HOST}.${suffix}:${ES_PORT}/_data_stream?pretty" | grep "${ts}" | cut -f2 -d':' | tr -d ' ",' | sed -E 's/-[[:digit:]]{4}.[[:digit:]]{2}.[[:digit:]]{2}-[[:digit:]]{6}//' | grep -v mb-"${sname}" | sort -u | cut -c 4-)")
      for ds in "${data_streams[@]}"; do
        curl --silent -k -u "${user}":"${passwd}" -XPOST "https://${ES_HOST}.${suffix}:${ES_PORT}/${ds}/_rollover" >/dev/null
        echo "Processing time series rollover for data_stream:${ds}"
      done
    else
      #
      # Get list of aliases
      aliases=("$(curl --silent -k -u "${user}":"${passwd}" -XGET "https://${ES_HOST}.${suffix}:${ES_PORT}/_cat/aliases/?v=false&h=alias" | grep "${ts}" | grep -v ^restored | sed -E 's/-[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}-[[:digit:]]{6}//' | sort -u)")

      for alias in "${aliases[@]}"; do
        curl --silent -k -u "${user}":"${passwd}" -XPOST "https://${ES_HOST}.${suffix}:${ES_PORT}/${alias}/_rollover" >/dev/null
        echo "Processing time series rollover for index:${alias}"
      done
    fi
  done
}

# Function: non_timeseriesCCR
# Parameters: None
# Desc: Setup follow Cross Cluster Replication (CCR) for non-time series indexes
function non_timeseriesCCR() {
  #
  # Add non-time series indexes
  #
  non_timeseries=(
    dcgs-acas-iaas-ent
    dcgs-current-healthdata-iaas-ent
  )

  for non_ts in "${non_timeseries[@]}"; do

    curl --silent -k -u "${user}":"${passwd}" -XPUT "https://${ES_HOST}:${ES_PORT}/${non_ts}-${suffix}/_ccr/follow?wait_for_active_shards=1&pretty" -H 'Content-Type: application/json' -d'
{
  "remote_cluster" : "'"${suffix^^}_Cluster"'",
  "leader_index" : "'"${non_ts}"'"
}
'
    echo "Processing non-time series rollover :${non_ts}"
  done
} >/dev/null

####################################################
#Main                                              #
####################################################

if [ "${snum}" == '00' ]; then
  suffix="wch"
  sname="ech"
else
  suffix="ech"
  sname="wch"
fi

#
# Get Version
#
bsver=$(/usr/share/elasticsearch/bin/elasticsearch --version | cut -f2 -d' ' | sed 's/.$//')

if [ -z "$bsver" ]; then
  echo
  echo "*** ERROR *** "
  echo "Unable to determine elasticsearch version, unable to bootstrap indexes."
  echo "Contact an Elastic SME for guidance..."
  echo
  exit 1
fi

/bin/clear
echo "."
read -sp "User <$user> will be used to Update cluster settings for replication in elastic, please enter the password for $user: " -r passwd </dev/tty
echo

#
# Set up Remote Connection
#
setupRC

#
# Check to see if the cluster connected
#
remoteinfo=$(curl --silent -k -u "${user}":"${passwd}" https://elastic-node-1.${suffix}:9200/_remote/info?pretty --write-out '%{http_code}')

connected=$(echo "${remoteinfo}" | grep -oP '"connected"\s*:\s*\K\w+')
if [ "$connected" = false ]; then
  echo
  echo "*** ERROR *** "
  echo "Not connected to remote cluster. Unable to continue"
  echo "Contact an Elastic SME to verify remote cluster connectivity..."
  echo
  exit 1
fi

#
# Set up time series CCR (auto_follow leader)
#
timeseriesCCR

#
# Set up non-time series (follow leader)
#
non_timeseriesCCR
