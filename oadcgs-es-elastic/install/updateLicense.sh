#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Loads license fle elasticLicense.json into Elastic
#
# Tracking #: CR-2020-OADCGS-086
#
# File name: updateLicense.sh
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

# Set up the site data for each environment
declare -A licenses=(
  ["UNCLASS"]="AFDCGS-NON_production-LOW-Expires-May-29-2024.json"
  ["CTEL"]="AFDCGS-NON_production-LOW-Expires-May-29-2024.json"
  ["CTEH"]="AFDCGS-NON_Production-HIGH-Expires-May-29-2024.json"
  ["MTEL"]="AFDCGS-NON_production-LOW-Expires-May-29-2024.json"
  ["MTEH"]="AFDCGS-NON_Production-HIGH-Expires-May-29-2024.json"
  ["RELL"]="AFDCGS-Production-REL-Expires-May-29-2024.json"
  ["RELH"]="AFDCGS-Production-REL-Expires-May-29-2024.json"
  ["LOW"]="AFDCGS-Production-LOW-Expires-May-29-2024.json"
  ["HIGH"]="AFDCGS-Production-HIGH-Expires-May-29-2024.json"
)

read -sp "User <$user> will be used to update the license in elastic, please enter the password for $user: " -r passwd </dev/tty
echo

# Ensure password provided is valid
pwcheck=$(curl -k --silent -u "${user}":"${passwd}" "https://${ES_HOST}:${ES_PORT}/_cluster/health" --write-out '%{http_code}')
retval=${pwcheck: -3}
if [[ $retval != 200 ]]; then
  echo
  echo "Unable to communcate with Elasticsearch. Did you enter your password correctly?"
  echo "Script aborted, please try again."
  echo
  exit
fi

site=$(hostname | cut -c 1-3)
site=${site^^}

case "$site" in
U00 | U0A)
  echo -n "Detected UNCLASSIFIED environment."
  env="UNCLASS"
  ;;
S24 | S70 | SR0)
  echo
  read -r -p "Detected CTE Low / MTE Low environment, enter environment (CTEL or MTEL): " env
  env=${env^^} # converts input to uppercase
  if [[ "$env" == "MTEL" || "$env" == "CTEL" ]]; then
    echo "Using ${env} environment."
  else
    echo "Invalid input. Expected 'CTEL' or 'MTEL'. Script aborted." >&2
    exit 1
  fi
  ;;
T24 | T70 | TR0)
  echo
  read -r -p "Detected CTE High / MTE High environment, enter environment (CTEH or MTEH): " env
  env=${env^^} # converts input to uppercase
  if [[ "$env" == "MTEH" || "$env" == "CTEH" ]]; then
    echo "Using ${env} environment."
  else
    echo "Invalid input. Expected 'CTEH' or 'MTEH'. Script aborted." >&2
    exit 1
  fi
  ;;
S00 | S0A)
  echo -n "Detected SECRET environment."
  echo
  env="LOW"
  ;;
T00 | T0A)
  echo -n "Detected TS/SCI environment."
  echo
  env="HIGH"
  ;;
SD1 | SD2)
  echo -n "Detected REL Low environment."
  echo
  env="RELL"
  ;;
TD1 | TD2)
  echo -n "Detected REL High environment."
  echo
  env="RELH"
  ;;
*)
  echo "Unknown environment for site: $site. Script aborted." >&2
  exit 1
  ;;
esac

license=${licenses["$env"]}

fileloc="satrepo/pulp/content/oadcgs/Library/custom/Elastic_Client/Elastic_Files"

status=$(curl -head --silent https://"$fileloc"/install/licenses/"$license" | head -n 1)
if ! echo "$status" | grep -q OK; then
  echo "License ${license} not found, contact Elastic SME for guidance."
  exit
fi

curl -k --silent https://"$fileloc"/install/licenses/"$license" >/tmp/elasticLicense.json

curl -k -XPUT -u "${user}":"${passwd}" https://${ES_HOST}:${ES_PORT}/_license -H "Content-Type: application/json" -d @/tmp/elasticLicense.json

#################################################################################
#
#			    Unclassified
#
#################################################################################
