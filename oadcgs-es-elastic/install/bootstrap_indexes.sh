#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Bootstraps initial indexes.  Indexes being bootstrapped are
#          listed in the "indexes" array
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: bootstrap_indexes.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.1
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, date it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2020-OADCGS-086, Steve Truxal, 2020-07-21: Original Version
#   v1.01, CR-2021-OADCGS-035, Steve Truxal, 2022-01-20: Update for Upgrades
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
# Initilize variables
#
user=$SUDO_USER
ES_HOST="elastic-node-1"
ES_PORT="9200"

clear

#read -rp "Which indices would you like to bootstrap? (Example: dcgs-vsphere-iaas-ent) =>" indices </dev/tty

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
bsver=$(/usr/share/elasticsearch/bin/elasticsearch --version | /bin/cut -f2 -d' ' | /bin/sed 's/.$//')

if [ -z "$bsver" ]; then
  echo
  echo "*** ERROR *** "
  echo "Unable to determine elasticsearch version, this script must be run on an elasticsearch node..."
  echo
  exit 1
fi

echo "Bootstrapping for version ${bsver}"
echo
echo "*** NOTICE *** "
echo "This script will verify aliases for all all indexes.  If an alias does not exist it will"
echo "be bootstrapped and the intial alias will be created.  Beats indexes for version \"${bsver}\" "
echo "will recieve their initial bootstrapping"
echo
read -p "Is this the version you are upgrading to? <y/n> " -n 1 -r </dev/tty
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborting script..."
  exit 1
fi

echo
read -sp "User <$user> will be used for bootstrapping, please enter the password for $user: " -r passwd </dev/tty
echo

#
# This is an array of all indexes to be bootstrapped
#
indexes=(
  dcgs-hbss_epo-iaas-ent
  dcgs-hbss_epo_dlp-iaas-ent
  dcgs-db_idm-iaas-ent
  dcgs-db_sccm-iaas-ent
  dcgs-device_idrac_fc6xx-iaas-ent
  dcgs-device_idrac_r6xx-iaas-ent
  dcgs-device_switch_cat-iaas-ent
  dcgs-device_fx2-iaas-ent
  dcgs-device_datadomain-iaas-ent
  dcgs-device_switch_5k-iaas-ent
  dcgs-device_switch_7k-iaas-ent
  dcgs-device_isilon-iaas-ent
  dcgs-device_xtremio-iaas-ent
  dcgs-healthdata-iaas-ent
  dcgs-db_puppet-iaas-ent
  dcgs-db_eracent-iaas-ent
  dcgs-db_postgres-iaas-ent
  dcgs-vsphere-iaas-ent
  dcgs-hbss-metrics-iaas-ent
  dcgs-iptables-iaas-ent
  dcgs-db_sqlserver-iaas-ent
  dcgs-filebeat-geo-ha-render-logs
  filebeat-"${bsver}"
  heartbeat-"${bsver}"
  winlogbeat-"${bsver}"
  dcgs-filebeat-soaesb
  dcgs-filebeat-geo-ha-socetgxp
  dcgs-filebeat-geo-ha-gxpxplorer
  dcgs-filebeat-geo-fmv-maas_logs
  dcgs-loginsight_syslog-iaas-ent
  dcgs-logindata-iaas-ent
  dcgs-unparsed-syslog-iaas-ent
  dcgs-filebeat-geo-ha-unicorn-logs
  dcgs-filebeat-geo-sensors-ecp
  dcgs-filebeat-sr-ashes
)

for index in "${indexes[@]}"; do

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
      echo "Alias Found"
    fi
  else
    echo
    echo "*** ERROR *** "
    echo "Bad return code from curl: $retcode, did you enter your password incorrectly?"
    break
  fi
done

# bootstrap/create non-time series indexes if they don't exist
non_timeseries=(
  dcgs-acas-iaas-ent
  dcgs-current-healthdata-iaas-ent
)

for index in "${non_timeseries[@]}"; do
  indexcheck=$(curl -k --silent -I -u "${user}":"${passwd}" "https://${ES_HOST}:${ES_PORT}/$index?pretty" --write-out '%{http_code}')
  retval=${indexcheck: -3}
  if [[ $retval != 200 ]]; then
    echo "Creating non-time series index: $index"
    curl -k -XPUT -u "${user}":"${passwd}" "https://${ES_HOST}:${ES_PORT}/$index?pretty"
    echo
  else
    echo "Index $index already exists."
    echo
  fi
done

echo
echo
echo "script complete."
echo
echo
#################################################################################
#
#			    Unclassified
#
#################################################################################
