#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Updates logstash Centralized Pipelines in Kibana
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: update_logstash_pipelines.sh
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

#
# Initialize variables
#

fileloc="satrepo/pulp/content/oadcgs/Library/custom/Elastic_Client/Elastic_Files"
user=$SUDO_USER
class="$(hostname | cut -c 1)"
classification="${class^^}"

read -sp "User <$user> will be used to update logstash pipelines in elastic, please enter the password for $user: " -r passwd </dev/tty
echo

#
# This is an array of all pipeline names to be loaded
#
pipelines=(
  esp_filebeat
  esp_filebeat-logstash
  esp_filebeat-singleworker
  esp_hbss_epo
  esp_hbss_dlp
  esp_hbss_dlp-via-connector
  esp_heartbeat
  esp_loginsight
  esp_sccm_database
  esp_winlogbeat
  esp_eracent_database
  esp_hbss_metrics
  esp_puppet_database
  esp_postgres
  esp_linux_syslog
  esp_metricbeat
  esp_syslog_tcp
  esp_syslog_udp
)

#
# pull each pipeline from the satellite server and load into kibana
#
for pipeline in "${pipelines[@]}"; do
  echo "putting pipeline: $pipeline "
  curl -k --silent https://"$fileloc"/install/pipelines/"${pipeline}" | sed -z 's/\n/\\n/g;;$ s/\\n$/\n/' >/tmp/"${pipeline}"
  #
  # dynamically checking of the esp_sccm_database for classification
  #
  if [[ "${pipeline}" == "esp_sccm_database" ]]; then
    if [[ "${classification}" == "T" ]]; then
      echo -n "Detected TS/SCI environment, "
      sed -i 's/CM_U00.dbo.v_StatMsgWithInsStrings/CM_T00.dbo.v_StatMsgWithInsStrings/g' /tmp/"${pipeline}"

    elif [[ "${classification}" == "S" ]]; then
      echo -n "Detected SECRET environment, "
      sed -i 's/CM_U00.dbo.v_StatMsgWithInsStrings/CM_S00.dbo.v_StatMsgWithInsStrings/g' /tmp/"${pipeline}"

    else
      echo -n "Detected UNCLASSIFIED environment, "
    fi
    echo "updating SCCM database name to reflect environment."
  fi

  loadpipe=$(curl -w 'return_code=%{http_code}\n' --silent -k -XPUT -u "${user}":"${passwd}" https://kibana/api/logstash/pipeline/"${pipeline}" -H 'kbn-xsrf:true' -H 'Content-Type: application/json' -d@/tmp/"${pipeline}")
  retcode=$(echo "$loadpipe" | awk -F 'return_code=' '{print $2}' | sed '/^$/d')
  if [ "$retcode" != "204" ]; then
    echo
    echo "*** ERROR LOADING PIPELINE: $pipeline *** "
    echo "Bad return code from curl: $retcode, Incorrect Password or Empty Pipeline."
    break
  fi

  rm /tmp/"${pipeline}"
done

#################################################################################
#
#			    Unclassified
#
#################################################################################
