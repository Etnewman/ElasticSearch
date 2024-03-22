#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Configures the database string for the UNICORN pipeline
#
# Tracking #: CR-2020-OADCGS-086
#
# File name: activate_unicorn.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, date it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2020-OADCGS-086, Robert Williamson, 2022-10-28: Original Version
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
index="dcgs-db_geo-ha-unicorn-iaas-ent"

echo "IMPORTANT: Prior to using this script the Elastic service account at the site where this feature will be activated must be given permission to read data from the UNICORN Database."
echo

read -sp "User <$user> will be used to setup and activate UNICORN pipeline, please enter password for $user: " -r passwd </dev/tty
echo

curl -k --silent https://"$fileloc"/install/pipelines/esp_unicorn_database | sed -z 's/\n/\\n/g;;$ s/\\n$/\n/' >/tmp/esp_unicorn_database-candidate
#
# prompt user to fill out info for the UNICORN database string
#

read -r -p "Enter the data source for the UNICORN database: " unicorn_hostname
sed -i "s/HOSTNAME/${unicorn_hostname}/g" /tmp/esp_unicorn_database-candidate

read -r -p "Enter the initial catalog for the UNICORN database: " unicorn_database
sed -i "s/DATABASE_NAME/${unicorn_database}/g" /tmp/esp_unicorn_database-candidate

#
# Load pipeline
#

echo "esp_unicorn_database pipeline configured, now loading. . ."

loadpipe=$(curl -w 'return_code=%{http_code}\n' --silent -k -XPUT -u "${user}":"${passwd}" https://kibana/api/logstash/pipeline/esp_unicorn_database -H 'kbn-xsrf:true' -H 'Content-Type: application/json' -d@/tmp/esp_unicorn_database-candidate)
retcode=$(echo "$loadpipe" | awk -F 'return_code=' '{print $2}' | sed '/^$/d')
if [ "$retcode" != "204" ]; then
  echo
  echo "*** ERROR LOADING ESP_UNICORN_DATABASE PIPELINE ***"
  echo "Bad return code from curl: $retcode, incorrect password or empty pipeline."
  exit
fi

echo "esp_unicorn_database pipeline loaded successfully."
echo
echo "Note that this pipeline will not be used until added to the logstash.yml file at the site identified to pull UNICORN data. This pipeline SHOULD ONLY be used on one logstash instance."
# Start bootstrapping

echo -n "checking alias for $index..."

alias=$(curl -w 'return_code=%{http_code}\n' --silent -k -XGET -u "${user}":"${passwd}" "https://${ES_HOST}:${ES_PORT}/_cat/aliases/$index?h=alias,is_write_index")

# shellcheck disable=SC2206
alias=($alias)

haswrite="false"
for ((i = 0; i < ${#alias[@]}; i++)); do

  if [[ ${alias[i]} == "$index" ]]; then
    if [[ ${alias[++i]} == "true" ]]; then
      haswrite="true"
    fi
  elif [[ ${alias[i]} =~ return.* ]]; then
    retcode=$(echo "${alias[i]}" | awk -F 'return_code=' '{print $2}' | sed '/^$/d')
  fi
done

if [ "$retcode" == "200" ]; then
  if [ ${haswrite} == "false" ]; then
    echo "No Alias found for index: $index, creating..."
    curl -k -u "${user}":"${passwd}" -XPUT "https://elastic-node-1:9200/%3C${index}-%7Bnow%2Fm%7Byyy-MM-dd%7D%7D-000001%3E" -H 'Content-Type: application/json' -d'
{
    "aliases" : {
        "'"$index"'" : {
             "is_write_index" : true
        }
     }
}
'

  else
    echo "Alias Found."
  fi
else
  echo
  echo "*** ERROR *** "
  echo "Bad return code from curl: $retcode, did you enter your password incorrectly?"
fi

#################################################################################
#
#			    Unclassified
#
#################################################################################
