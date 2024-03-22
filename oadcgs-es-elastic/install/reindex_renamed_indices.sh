#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Reindex indexes whose name has changed due to alias change.
#          Delete the old indexes after reindexing is completed.
#
# Tracking #: CR-2022-OADCGS-21770
#
# File name: reindex_renamed_indices.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, date it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.0, CR-2022-OADCGS-21770, Joel Watlington, 05/17/2022: Original Version
#   v1.1, CR-2022-OADCGS-21770, Joel Watlington, 04/21/2023: Add option for
#            a script within the reindex command
#
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

declare -A indexArr
declare -A scriptArr

user=$SUDO_USER
ES_HOST="elastic-node-1"
ES_PORT="9200"

#Add indexes to be re-indexed here
#format : indexArr+= (["old_index"]="new_index")

#Optional: For each index requiring renaming or adding fields, use this
# (content must be one line with no c/r's and no tabs, will be used in a string inside double-quotes which within a string in single-quotes so all quotes must be 3 backslashes followed by double-quote)
#format : scriptArr+= ([\\\"old_index\\\"]=\\\"script content\\\")
#examples:
#  Rename field - ctx._source[\\\"newfield\\\"] = ctx._source.remove(\\\"oldfield\\\");
#  Copy field   - ctx._source[\\\"newfield\\\"] = ctx._source.oldfield;
#  New field    - ctx._source[\\\"newfield\\\"] = \\\"content\\\";
#  Conditional  - if (ctx._source.containsKey(\\\"file\\\")){script content}
#    (Without conditional, if oldfield doesn't exist, newfield is created with content 'null')
#  Sub-field stored in Index (rather than dot-notation)
#               - if (ctx._source.containsKey(\\\"field\\\") && ctx._source.field.containsKey(\\\"subfield\\\")){
#               - ctx._source[\\\"newfield\\\"] = ctx._source.field.remove(\\\"oldfield\\\")}
#  Concatenate  - ctx._source[\\\"newfield\\\"] = ctx._source.field1 + \\\" \\\" + ctx._source.field2

indexArr+=(["dcgs-filebeat-geo-ha-socet-socetevent-log"]="dcgs-filebeat-geo-ha-socetgxp-olddata")
scriptArr+=(["dcgs-filebeat-geo-ha-socet-socetevent-log"]="ctx._source[\\\"event.original\\\"] = ctx._source.remove(\\\"log.original\\\"); ctx._source[\\\"app.Kind\\\"] = \\\"Mission\\\"; ctx._source[\\\"app.Category\\\"] = \\\"HA\\\"; ctx._source[\\\"app.Name\\\"] = \\\"SOCET\\\";ctx._source[\\\"app.DocType\\\"] = \\\"log\\\"; ctx._source[\\\"app.DocSubtype\\\"] = \\\"event\\\";")

indexArr+=(["dcgs-filebeat-geo-ha-socet-socetraw-log"]="dcgs-filebeat-geo-ha-socetgxp-olddata")
scriptArr+=(["dcgs-filebeat-geo-ha-socet-socetraw-log"]="ctx._source[\\\"event.original\\\"] = ctx._source.remove(\\\"log.original\\\"); ctx._source[\\\"app.Kind\\\"] = \\\"Mission\\\"; ctx._source[\\\"app.Category\\\"] = \\\"HA\\\"; ctx._source[\\\"app.Name\\\"] = \\\"SOCET\\\"; ctx._source[\\\"app.DocType\\\"] = \\\"log\\\"; ctx._source[\\\"app.DocSubtype\\\"] = \\\"raw\\\";")

indexArr+=(["dcgs-filebeat-geo-ha-xplorer-ecs-log"]="dcgs-filebeat-geo-ha-gxpxplorer-olddata")
scriptArr+=(["dcgs-filebeat-geo-ha-xplorer-ecs-log"]="ctx._source[\\\"event.original\\\"] = ctx._source.message; if (ctx._source.containsKey(\\\"file\\\")){ctx._source[\\\"file.name\\\"] = ctx._source.remove(\\\"file\\\")} if (ctx._source.containsKey(\\\"log\\\") && ctx._source.log.containsKey(\\\"offset\\\")){ctx._source[\\\"log.origin.file.line\\\"] = ctx._source.log.remove(\\\"offset\\\")} if (ctx._source.containsKey(\\\"log\\\") && ctx._source.log.containsKey(\\\"timestamp\\\")){ctx._source[\\\"event.ingested\\\"] = ctx._source.log.remove(\\\"timestamp\\\")} if (ctx._source.containsKey(\\\"timestamp\\\")){ctx._source[\\\"event.created\\\"] = ctx._source.remove(\\\"timestamp\\\")} if (ctx._source.containsKey(\\\"startTime\\\")){ctx._source[\\\"startTime\\\"] = ctx._source.remove(\\\"startTime\\\")} if (ctx._source.containsKey(\\\"endTime\\\")){ctx._source[\\\"endTime\\\"] = ctx._source.remove(\\\"endTime\\\")} if (ctx._source.containsKey(\\\"user\\\")){ctx._source[\\\"user.name\\\"] = ctx._source.remove(\\\"user\\\")} ctx._source[\\\"app.Kind\\\"] = \\\"Mission\\\"; ctx._source[\\\"app.Category\\\"] = \\\"HA\\\"; ctx._source[\\\"app.Name\\\"] = \\\"GXP_XPLORER\\\"; ctx._source[\\\"app.DocType\\\"] = \\\"log\\\"; ctx._source[\\\"app.DocSubtype\\\"] = \\\"ecs\\\";")

indexArr+=(["dcgs-filebeat-geo-ha-xplorer-event-log"]="dcgs-filebeat-geo-ha-gxpxplorer-olddata")
scriptArr+=(["dcgs-filebeat-geo-ha-xplorer-event-log"]="ctx._source[\\\"event.original\\\"] = ctx._source.message; if (ctx._source.containsKey(\\\"file\\\")){ctx._source[\\\"file.name\\\"] = ctx._source.remove(\\\"file\\\")} if (ctx._source.containsKey(\\\"log\\\") && ctx._source.log.containsKey(\\\"offset\\\")){ctx._source[\\\"log.origin.file.line\\\"] = ctx._source.log.remove(\\\"offset\\\")} if (ctx._source.containsKey(\\\"log\\\") && ctx._source.log.containsKey(\\\"timestamp\\\")){ctx._source[\\\"event.ingested\\\"] = ctx._source.log.remove(\\\"timestamp\\\")} if (ctx._source.containsKey(\\\"timestamp\\\")){ctx._source[\\\"event.created\\\"] = ctx._source.remove(\\\"timestamp\\\")} if (ctx._source.containsKey(\\\"startTime\\\")){ctx._source[\\\"startTime\\\"] = ctx._source.remove(\\\"startTime\\\")} if (ctx._source.containsKey(\\\"endTime\\\")){ctx._source[\\\"endTime\\\"] = ctx._source.remove(\\\"endTime\\\")} if (ctx._source.containsKey(\\\"user\\\")){ctx._source[\\\"user.name\\\"] = ctx._source.remove(\\\"user\\\")} ctx._source[\\\"app.Kind\\\"] = \\\"Mission\\\"; ctx._source[\\\"app.Category\\\"] = \\\"HA\\\"; ctx._source[\\\"app.Name\\\"] = \\\"GXP_XPLORER\\\"; ctx._source[\\\"app.DocType\\\"] = \\\"log\\\"; ctx._source[\\\"app.DocSubtype\\\"] = \\\"event\\\";")

indexArr+=(["dcgs-filebeat-geo-ha-xplorer-notification-log"]="dcgs-filebeat-geo-ha-gxpxplorer-olddata")
scriptArr+=(["dcgs-filebeat-geo-ha-xplorer-notification-log"]="ctx._source[\\\"event.original\\\"] = ctx._source.message; if (ctx._source.containsKey(\\\"file\\\")){ctx._source[\\\"file.name\\\"] = ctx._source.remove(\\\"file\\\")} if (ctx._source.containsKey(\\\"log\\\") && ctx._source.log.containsKey(\\\"offset\\\")){ctx._source[\\\"log.origin.file.line\\\"] = ctx._source.log.remove(\\\"offset\\\")} if (ctx._source.containsKey(\\\"log\\\") && ctx._source.log.containsKey(\\\"timestamp\\\")){ctx._source[\\\"event.ingested\\\"] = ctx._source.log.remove(\\\"timestamp\\\")} if (ctx._source.containsKey(\\\"timestamp\\\")){ctx._source[\\\"event.created\\\"] = ctx._source.remove(\\\"timestamp\\\")} if (ctx._source.containsKey(\\\"startTime\\\")){ctx._source[\\\"startTime\\\"] = ctx._source.remove(\\\"startTime\\\")} if (ctx._source.containsKey(\\\"endTime\\\")){ctx._source[\\\"endTime\\\"] = ctx._source.remove(\\\"endTime\\\")} if (ctx._source.containsKey(\\\"user\\\")){ctx._source[\\\"user.name\\\"] = ctx._source.remove(\\\"user\\\")} ctx._source[\\\"app.Kind\\\"] = \\\"Mission\\\"; ctx._source[\\\"app.Category\\\"] = \\\"HA\\\"; ctx._source[\\\"app.Name\\\"] = \\\"GXP_XPLORER\\\"; ctx._source[\\\"app.DocType\\\"] = \\\"log\\\"; ctx._source[\\\"app.DocSubtype\\\"] = \\\"notification\\\";")

indexArr+=(["dcgs-filebeat-geo-fmv-maas-logs"]="dcgs-filebeat-geo-fmv-maas_logs-olddata")
scriptArr+=(["dcgs-filebeat-geo-fmv-maas-logs"]="ctx._source[\\\"event.original\\\"] = ctx._source.timestamp + \\\" \\\" + ctx._source.time + \\\" \\\" + ctx._source.priority + \\\" \\\" + ctx._source.thread + \\\" \\\" + ctx._source.location + \\\" \\\" + ctx._source.message; if (ctx._source.containsKey(\\\"log\\\") && ctx._source.log.containsKey(\\\"message\\\") && ctx._source.log.message.containsKey(\\\"length\\\")){ctx._source[\\\"event.originalLength\\\"] = ctx._source.log.message.remove(\\\"length\\\")} if (ctx._source.containsKey(\\\"log\\\") && ctx._source.log.containsKey(\\\"time\\\")){ctx._source[\\\"event.createdTime\\\"] = ctx._source.log.remove(\\\"time\\\")} if (ctx._source.containsKey(\\\"log\\\") && ctx._source.log.containsKey(\\\"timestamp\\\")){ctx._source[\\\"event.created\\\"] = ctx._source.log.remove(\\\"timestamp\\\")} if (ctx._source.containsKey(\\\"priority\\\")){ctx._source[\\\"log.level\\\"] = ctx._source.remove(\\\"priority\\\")} if (ctx._source.containsKey(\\\"priority_num\\\")){ctx._source[\\\"log.level_Num\\\"] = ctx._source.remove(\\\"priority_num\\\")} if (ctx._source.containsKey(\\\"user\\\")){ctx._source[\\\"user.name\\\"] = ctx._source.remove(\\\"user\\\")} ctx._source[\\\"app.Kind\\\"] = \\\"Mission\\\"; ctx._source[\\\"app.Category\\\"] = \\\"FMV\\\"; ctx._source[\\\"app.Name\\\"] = \\\"MAAS\\\"; ctx._source[\\\"app.DocType\\\"] = \\\"log\\\"; if (ctx._source.containsKey(\\\"tags\\\") && ctx._source.tags.contains(\\\"truncated_msg\\\")){ctx._source[\\\"app.DocSubtype\\\"] = \\\"truncated_msg\\\";}else {ctx._source[\\\"app.DocSubtype\\\"] = \\\"maas\\\";}")

if [ -z "$user" ]; then
  echo "ERROR: Script needs USER defined."
  exit 1
fi
read -sp "User <$user> will be used to reindex, please enter the password for $user: " -r passwd </dev/tty
echo

for key in "${!indexArr[@]}"; do

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

  echo
  echo "Reindexing indices using alias:${key} to new alias: ${indexArr[${key}]}"

  indices_list=$(curl --silent -k -XGET -u "${user}":"${passwd}" "https://${ES_HOST}:${ES_PORT}/_cat/indices/${key}*?h=index,dc")

  if [ "$indices_list" == "" ]; then
    echo "No indices matched ${key} alias for reindexing, skipping."
    continue
  fi

  # shellcheck disable=SC2206
  indexes=($indices_list)

  echo " "
  for ((i = 0; i < ${#indexes[@]}; i = i + 2)); do
    index=${indexes[$i]}
    doc_count=${indexes[$i + 1]}
    if [ "${doc_count}" -gt "0" ]; then
      new_index=${indexArr[${key}]}-$( (echo "${index}" | rev | cut -f1-4 -d- | rev))
      script=${scriptArr[${key}]}
      printf 'Reindexing %10s documents in index: %s to --> %s\n' "${doc_count}" "${index}" "${new_index}"
      if [ "$script" == "" ]; then
        reindex=$(curl -k --silent -XPOST -u "${user}":"${passwd}" "https://${ES_HOST}:${ES_PORT}/_reindex?pretty" -H 'Content-Type: application/json' -d'{  "source": {    "index": "'"${index}"'"  },  "dest": {    "index": "'"${new_index}"'"  }}' --write-out '%{http_code}' --silent)
      else
        reindex=$(curl -k --silent -XPOST -u "${user}":"${passwd}" "https://${ES_HOST}:${ES_PORT}/_reindex?pretty" -H 'Content-Type: application/json' -d'{  "source": {    "index": "'"${index}"'"  },  "dest": {    "index": "'"${new_index}"'"  },  "script": {    "source": "'"${script}"'"  }}' --write-out '%{http_code}' --silent)
      fi

      retval=${reindex: -3}
      if [[ $retval != 200 ]]; then
        echo "Unable to re-index ${index} to ${new_index}, Return code is: $retval"
        echo "Script aborted, please contact Elastic SME for guidance"
        echo "${reindex}"
        exit
      fi
      newalias=$(curl --silent -k -XPOST -u "${user}":"${passwd}" "https://${ES_HOST}:${ES_PORT}/_aliases" -H 'Content-Type: application/json' -d'{  "actions": [    {      "add": {        "index": "'"$new_index"'",        "alias": "'"${indexArr[${key}]}"'", "is_write_index": false      }    }    ]}' --write-out '%{http_code}' --silent)
      retval=${newalias: -3}
      if [[ $retval != 200 ]]; then
        echo "Unable to create alias for index ${new_index}, Return code is: $retval"
        echo "Script aborted, please contact Elastic SME for guidance"
        exit
      fi

      # Give index time to setup before trying to move to warm phase
      sleep 5

      move=$(curl -k --silent -XPOST -u "${user}":"${passwd}" "https://${ES_HOST}:${ES_PORT}/_ilm/move/${new_index}" -H 'Content-Type: application/json' -d'{ "current_step": { "phase": "hot", "action": "rollover", "name" : "check-rollover-ready" }, "next_step": { "phase": "warm", "action" : "complete", "name" : "complete" } }' --write-out '%{http_code}' --silent)
      retval=${move: -3}

      if [[ $retval != 200 ]]; then
        move=$(curl -k --silent -XPOST -u "${user}":"${passwd}" "https://${ES_HOST}:${ES_PORT}/_ilm/move/${new_index}" -H 'Content-Type: application/json' -d'{ "current_step": { "phase": "hot", "action": "rollover", "name" : "ERROR" }, "next_step": { "phase": "warm", "action" : "complete", "name" : "complete" } }' --write-out '%{http_code}' --silent)

        retval=${move: -3}

        if [[ $retval != 200 ]]; then
          echo "Unable to move $index to warm phase, please contact an Elastic SME for guidance."
        fi
      fi

    else
      echo "index ${index} is empty and will not be re-indexed"
    fi
    echo "Deleting old index $index"
    curl --silent -k -XDELETE -u "${user}":"${passwd}" "https://elastic-node-6:9200/$index?pretty"

  done
done
echo
echo
echo "Re-indexing done."
echo
echo

unset indexArr
