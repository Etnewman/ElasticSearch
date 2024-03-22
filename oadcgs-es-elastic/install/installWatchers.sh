#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: To install the array of Watchers into Elastic Search
#
# Tracking #: CR-2020-OADCGS-086
#
# File name: install_watchers.sh
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
fileloc="satrepo/pulp/content/oadcgs/Library/custom/Elastic_Client/Elastic_Files"
ES_HOST="elastic-node-1"
ES_PORT="9200"
clusterSites=()
watchers=(esw_current-healthdata-stale-state)

#
# Function to Put Watchers into Elastic
# $1 = clusterSite; $2 = watcher
#
function putWatcher() {
  w_check=$(curl -k --silent -u "${user}":"${passwd}" "https://${ES_HOST}.${1}:${ES_PORT}/_watcher/watch/${2}" --write-out '%{http_code}')
  w_retval=${w_check: -3}

  # Authentication failed
  if [ "$w_retval" == "401" ]; then
    echo "*** AUTHENTICATION FAILED ***"
    echo
    return
  fi

  # Get the Watcher from the Sat. Repo server
  curl -k --silent https://"$fileloc"/install/watchers/"${2}" >/tmp/"${2}"

  # If current-healthdata-updater, modify for site
  if [ "${2}" == "esw_current-healthdata-updater" ]; then
    if [[ "$1" == "wch" ]]; then
      DCGS_SITE="ech"
    else
      DCGS_SITE="wch"
    fi
    sed -i "s/(DCGS_SITE)/${DCGS_SITE}/g" /tmp/"${2}"
  fi

  # If watcher doesn't exist, put it into elastic
  if [ "$w_retval" == "404" ]; then
    echo "*** WATCHER DOES NOT EXIST, CREATING WATCHER: $2 ***"
    echo
    curl --silent -XPUT -u "${user}":"${passwd}" https://${ES_HOST}."${1}":${ES_PORT}/_watcher/watch/"${2}" -H 'Content-Type: application/json' -d@/tmp/"${2}"
    echo "*** SUCCESSFULLY INSTALLED WATCHER: $2 ***"
    echo
  else
    echo "*** REINSTALLING WATCHER: $2...***"
    echo
    # shellcheck disable=SC2034
    watcher_ret=$(curl --silent -XPUT -u "${user}":"${passwd}" https://${ES_HOST}."${1}":${ES_PORT}/_watcher/watch/"${2}" -H 'Content-Type: application/json' -d@/tmp/"${2}" --write-out '%{http_code}')
    echo "*** WATCHER: $2 REINSTALLED ***"
    echo
  fi

  rm /tmp/"${2}"
}

#
# Main
#

read -sp "User <$user> will be used to install the STALE-WATCHER into elastic, please enter the password for $user: " -r passwd </dev/tty
echo

# Query site of Elastic Cluster for Logstash destination
clusterSites=()
echo
read -p "Enter the primary Elastic cluster that the Watchers will run on (ex: ech, wch, isec). default [ech]: " -r clusterSite </dev/tty
clusterSite=${clusterSite:-ech}
clusterSites+=("$clusterSite")
echo

if [[ "${clusterSites[0]}" == "ech" ]]; then
  echo
  echo "Setting secondary cluster to wch..."
  clusterSites+=("wch")
  echo
fi

# Test connection to both Clusters before proceeding
for clusterSite in "${clusterSites[@]}"; do
  if [ -n "$clusterSite" ]; then
    pwcheck=$(curl -k --silent -u "${user}":"${passwd}" "https://${ES_HOST}.${clusterSite}:${ES_PORT}/_cluster/health" --write-out '%{http_code}')
    retval=${pwcheck: -3}
    if [[ $retval != 200 ]]; then
      echo
      echo "Unable to communicate with Elasticsearch. Did you enter your password correctly?"
      echo "CLUSTER: https://${ES_HOST}.${clusterSite}:${ES_PORT}"
      echo "Script aborted, please try again."
      echo
      exit
    fi
  fi
done

if [ ${#clusterSites[@]} -gt 1 ]; then
  watchers+=(esw_current-healthdata-updater)
fi

for clusterSite in "${clusterSites[@]}"; do
  for watcher in "${watchers[@]}"; do
    putWatcher "$clusterSite" "$watcher"
  done
done
