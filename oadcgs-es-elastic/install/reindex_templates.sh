#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Re-indexes indices
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: reindex_templates.sh
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
# Initilize variables
#
user=$SUDO_USER
ES_HOST="elastic-node-1"
ES_PORT="9200"
RI="-reindexed"

clear
read -sp "User <$user> will be used to reindex, please enter the password for $user: " -r passwd </dev/tty
echo

read -rp "Which indices would you like to reindex? (Example: idm) =>" indices </dev/tty

indices_list=$(curl --silent -k -XGET -u "${user}":"${passwd}" "https://${ES_HOST}:${ES_PORT}/_cat/indices/%2A?v=&s=index:desc" | awk '{print $3}' | sed -n '1!p' | grep -E "$indices")

if [ "$indices_list" == "" ]; then
  echo "No indices matched or password is incorrect"
  exit
fi

echo " "
printf '%s\n' "${indices_list[@]}"
read -rp "Are these the indices you wish to reindex? Yes/No=>" yn </dev/tty
case $yn in
[Yy]*) ;;
[Nn]*) exit ;;
*) echo "Please answer yes or no." ;;
esac

echo " "
for index in $indices_list; do
  new_index=$index${RI}

  reindex=$(curl -k -XPOST -u "${user}":"${passwd}" "https://${ES_HOST}:${ES_PORT}/_reindex?pretty" -H 'Content-Type: application/json' -d'{  "source": {    "index": "'"$index"'"  },  "dest": {    "index": "'"$new_index"'"  }}' --write-out '%{http_code}' --silent)

  retval=${reindex: -3}
  if [[ $retval != 200 ]]; then
    echo "Return code is: $retval"
    exit
  fi
  echo "Here is the reindex results: $reindex"

  alias=$(curl --silent -k -XPOST -u "${user}":"${passwd}" "https://${ES_HOST}:${ES_PORT}/_aliases" -H 'Content-Type: application/json' -d'{  "actions": [    {      "add": {        "index": "'"$new_index"'",        "alias": "'"${indices}"'"      }    }    ]}')
  echo " "
  echo "Here is the alias results: $alias"
  echo " "

  echo " "
  echo "Deleting old index $index"
  delete_old=$(curl --silent -k -XDELETE -u "${user}":"${passwd}" "https://elastic-node-6:9200/$index?pretty")
  echo "Here is the delete_old results: $delete_old"
done

echo
echo
echo "Re-indexing done."
echo
echo
#################################################################################
#
#			    Unclassified
#
#################################################################################
