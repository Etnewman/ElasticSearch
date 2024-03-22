#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Loads audit settings for Elastic
#
# Tracking #: CR-2020-OADCGS-086
#
# File name: load_auditsettings.sh
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
ES_HOST="elastic-node-1"
ES_PORT="9200"

echo
read -sp "User <$user> will be used to load audit settings into elastic, please enter the password for $user: " -r passwd </dev/tty

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

curl -XPUT -s -u "${user}":"${passwd}" https://${ES_HOST}:${ES_PORT}/_cluster/settings -H "Content-Type: application/json" -d'
{
  "persistent": {
    "xpack.security.audit.logfile.events.include" : [
      "anonymous_access_denied",
      "authentication_success",
      "authentication_failed",
      "realm_authentication_failed",
      "access_denied",
      "run_as_denied",
      "tampered_request",
      "connection_denied"
      ],
    "xpack.security.audit.logfile.events.ignore_filters": {
      "exclude_admin_users" : {
        "users" : [
          "_xpack_*",
          "ls_internal",
          "ls_admin",
          "logstash_internal",
          "logstash_admin_user",
          "logstash_system",
          "_system",
          "kibana-*",
          "querier-*",
          "metricbeat-user"
          ]
      }
    }
  }
}
'

echo
echo
echo "Audit settings loaded."
echo
echo
#################################################################################
#
#			    Unclassified
#
#################################################################################
