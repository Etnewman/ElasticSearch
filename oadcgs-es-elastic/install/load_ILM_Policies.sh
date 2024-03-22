#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Loads the default "Index Lifetime Management"(ILM) policy into
#          Elastic
#
# Tracking #: CR-2020-OADCGS-086
#
# File name: load_ILMPolicies.sh
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

policyname="dcgs_default_policy"
sevendaypolicy="dcgs_7day_policy"
searchablesnapshotpolicy=(
  dcgs_audits_syslog_policy
  dcgs_db_policy
  dcgs_hbss_epo_policy
  dcgs_syslog_policy
  dcgs_vsphere_policy
  dcgs_winlogbeat_policy
)
repository=(
  audits_syslog-ss
  database-ss
  hbss_epo-ss
  syslog-ss
  vsphere-ss
  winlogbeat-ss
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

# Creates repository for the indexes that will use searchable snapshots
for repo in "${repository[@]}"; do
  curl -XPUT -s -u "${user}":"${passwd}" https://elastic-node-1:9200/_snapshot/"$repo" -H "Content-Type: application/json" -d'
  {
    "type": "fs",
    "settings": {
      "location": "'"$repo"'"
    }
  }
  '
done

curl -XPUT -s -u "${user}":"${passwd}" https://elastic-node-1:9200/_snapshot/default-ss -H "Content-Type: application/json" -d'
{
  "type": "fs",
  "settings": {
    "location": "default-ss"
  }
}
'

echo
echo "Loading ILM Policy \"$policyname\" ..."
echo

curl -XPUT -s -u "${user}":"${passwd}" https://elastic-node-1:9200/_ilm/policy/$policyname -H "Content-Type: application/json" -d'
{
  "policy" : {
    "phases" : {
      "hot" : {
        "min_age" : "0ms",
        "actions" : {
          "readonly" : { },
          "rollover" : {
            "max_size" : "50gb",
            "max_age" : "7d"
          },
          "set_priority" : {
            "priority" : 100
          }
        }
      },
      "delete" : {
        "min_age" : "90d",
        "actions" : {
          "delete" : {
            "delete_searchable_snapshot" : false
          }
        }
      },
      "warm" : {
        "min_age" : "0ms",
        "actions" : {
          "allocate" : {
            "number_of_replicas" : 1,
            "include" : { },
            "exclude" : { }
          },
          "forcemerge" : {
            "max_num_segments" : 1
          },
          "readonly" : { },
          "set_priority" : {
            "priority" : 50
          },
          "shrink" : {
            "number_of_shards" : 1
          }
        }
      },
      "cold": {
          "min_age": "30d",
          "actions": {
            "migrate": {
              "enabled": false
            },
            "searchable_snapshot": {
              "snapshot_repository": "default-ss",
              "force_merge_index": true
            },
            "set_priority": {
              "priority": 50
            }
          }
        }
    }
  }
}
'
echo

curl -XPUT -s -u "${user}":"${passwd}" https://elastic-node-1:9200/_ilm/policy/$sevendaypolicy -H "Content-Type: application/json" -d'
{
  "policy" : {
    "phases" : {
      "hot" : {
        "min_age" : "0ms",
        "actions" : {
          "readonly" : { },
          "rollover" : {
            "max_size" : "50gb",
            "max_age" : "7d"
          },
          "set_priority" : {
            "priority" : 100
          }
        }
      },
      "delete" : {
        "min_age" : "7d",
        "actions" : {
          "delete" : {
            "delete_searchable_snapshot" : false
          }
        }
      }
    }
  }
}
'
echo

for policy in "${!searchablesnapshotpolicy[@]}"; do
  curl -XPUT -s -u "${user}":"${passwd}" https://elastic-node-1:9200/_ilm/policy/"${searchablesnapshotpolicy[policy]}" -H "Content-Type: application/json" -d'
  {
    "policy": {
      "phases": {
        "hot": {
          "min_age": "0ms",
          "actions": {
            "readonly": {},
            "rollover": {
              "max_age": "7d",
              "max_size": "50gb"
            },
            "set_priority": {
              "priority": 100
            }
          }
        },
        "warm": {
          "min_age": "0ms",
          "actions": {
            "allocate": {
              "number_of_replicas": 1,
              "include": {},
              "exclude": {},
              "require": {}
            },
            "forcemerge": {
              "max_num_segments": 1
            },
            "readonly": {},
            "set_priority": {
              "priority": 50
            },
            "shrink": {
              "number_of_shards": 1
            }
          }
        },
        "cold": {
          "min_age": "30d",
          "actions": {
            "migrate": {
              "enabled": false
            },
            "searchable_snapshot": {
              "snapshot_repository": "'"${repository[policy]}"'",
              "force_merge_index": true
            },
            "set_priority": {
              "priority": 50
            }
          }
        },
        "frozen": {
          "min_age": "60d",
          "actions": {
            "searchable_snapshot": {
              "snapshot_repository": "'"${repository[policy]}"'",
              "force_merge_index": true
            }
          }
        },
        "delete": {
          "min_age": "1825d",
          "actions": {
            "delete": {
              "delete_searchable_snapshot": false
            }
          }
        }
      }
    }
  }
  '
  echo
done

echo
echo
echo "ILM Policy Loaded."
echo
echo

#################################################################################
#
#			    Unclassified
#
#################################################################################
