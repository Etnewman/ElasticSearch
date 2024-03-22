#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Loads Kibna roles into Elastic
#
# Tracking #: CR-2020-OADCGS-086
#
# File name: load_roles.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, date it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2020-OADCGS-086, Steve Truxal, 2020-07-31: Original Version
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

ES_HOST="elastic-node-1"
ES_PORT="9200"

if [ -n "$1" ] && [ "$1" == "install" ]; then
  # Initial setup will used static password
  username="elastic"
  passwd="elastic"
  action="Creating"
else
  username=$SUDO_USER
  action="Updating"

  echo "."
  read -sp "User <$username> will be used for interaction with elastic, please enter the password for $username: " -r passwd </dev/tty
  echo
fi

# Ensure password provided is valid
pwcheck=$(curl -k --silent -u "${username}":"${passwd}" "https://${ES_HOST}:${ES_PORT}/_cluster/health" --write-out '%{http_code}')
retval=${pwcheck: -3}
if [[ $retval != 200 ]]; then
  echo
  echo "Unable to communcate with Elasticsearch. Password incorrect or improper usage."
  echo "Script aborted, please try again."
  echo
  echo "Usage: "
  echo "   For fresh installs: "
  echo "       curl -s -k https://xxsu01ro01.$(hostname -d)/yum/elastic/install/load_roles.sh | bash -s install"
  echo
  echo "   For upgrades: "
  echo "       curl -s -k https://xxsu01ro01.$(hostname -d)/yum/elastic/install/load_roles.sh | bash "
  echo
  exit
fi

rolename="dcgs_junior_kibana_admin"
echo -en "\n${action} role: ${rolename}"
curl -XPUT -s -u "${username}":"${passwd}" https://${ES_HOST}:${ES_PORT}/_security/role/${rolename} -H "Content-Type: application/json" -d'
{
    "cluster" : [
      "create_snapshot",
      "manage_index_templates",
      "manage_ingest_pipelines",
      "manage_logstash_pipelines",
      "manage_ml",
      "manage_pipeline",
      "manage_transform",
      "monitor",
      "read_ilm",
      "read_ccr",
      "read_slm",
      "read_security"
    ],
    "indices" : [
      {
        "names" : [
          "/@&~((dcgs-db_(sccm|idm)-iaas-ent.*)|((dcgs-hbss_epo)-iaas-ent.*)|((dcgs-audits_syslog)-iaas-ent.*)|((.siem-signals-default).*)|((dcgs-cyan).*)|((dcgs-acas).*))/"
        ],
        "privileges" : [
          "maintenance",
          "read",
          "read_cross_cluster",
          "view_index_metadata"
        ],
        "field_security" : {
          "grant" : [
            "*"
          ],
          "except" : [ ]
        },
        "allow_restricted_indices" : false
      },
      {
        "names" : [
          "dcgs-db_sccm-iaas-ent*",
          "dcgs-db_idm-iaas-ent*",
          "dcgs-hbss_epo-iaas-ent*",
          "dcgs-audits_syslog-iaas-ent*",
          ".siem-signals-default*",
          "dcgs-cyan*"
        ],
        "privileges" : [
          "maintenance",
          "monitor",
          "view_index_metadata"
        ],
        "field_security" : {
          "grant" : [
            "*"
          ]
        },
        "allow_restricted_indices" : false
      },
      {
        "names" : [
          ".logstash"
        ],
        "privileges" : [
          "read",
          "monitor"
        ],
        "field_security" : {
          "grant" : [
            "*"
          ]
        },
        "allow_restricted_indices" : false
      }
    ],
    "applications" : [
      {
        "application" : "kibana-.kibana",
        "privileges" : [
          "all"
        ],
        "resources" : [
          "*"
        ]
      }
    ],
    "run_as" : [ ],
    "metadata" : { },
    "transient_metadata" : {
      "enabled" : true
    }
}
'

rolename="dcgs_kibana_user"
echo -en "\n${action} role: $rolename"
curl -XPUT -s -u "${username}":"${passwd}" https://${ES_HOST}:${ES_PORT}/_security/role/${rolename} -H "Content-Type: application/json" -d'
{
    "cluster" : [
      "monitor",
      "monitor_ml",
      "monitor_data_frame_transforms",
      "monitor_rollup",
      "monitor_snapshot",
      "monitor_transform",
      "monitor_watcher",
      "read_ilm",
      "read_ccr"
    ],
    "indices" : [
      {
        "names" : [
          "/@&~((dcgs-db_(sccm|idm)-iaas-ent.*)|((dcgs-hbss_epo)-iaas-ent.*)|((dcgs-audits_syslog)-iaas-ent.*)|((.siem-signals-default).*)|((dcgs-cyan).*)|((dcgs-acas).*))/"
        ],
        "privileges" : [
          "read",
          "monitor",
          "read_cross_cluster",
          "view_index_metadata"
        ],
        "field_security" : {
          "grant" : [
            "*"
          ],
          "except" : [ ]
        },
        "allow_restricted_indices" : false
      }
    ],
    "applications" : [
      {
        "application" : "kibana-.kibana",
        "privileges" : [
          "feature_discover.minimal_read",
          "feature_discover.generate_report",
          "feature_dashboard.minimal_read",
          "feature_dashboard.url_create",
          "feature_dashboard.store_search_session",
          "feature_dashboard.generate_report",
          "feature_dashboard.download_csv_report",
          "feature_visualize.minimal_read",
          "feature_visualize.generate_report",
          "feature_canvas.read",
          "feature_maps.read",
          "feature_infrastructure.read",
          "feature_logs.read",
          "feature_uptime.read",
          "feature_graph.read",
          "feature_dev_tools.read",
          "feature_indexPatterns.read",
          "feature_savedObjectsManagement.read",
          "feature_advancedSettings.read",
          "feature_ingestManager.read",
          "feature_ml.read",
          "feature_observabilityCases.all",
          "feature_apm.read",
          "feature_savedObjectsTagging.read"
        ],
        "resources" : [
          "space:default",
          "space:default-depricated",
          "space:baseline"
        ]
      },
      {
        "application" : "kibana-.kibana",
        "privileges" : [
          "feature_discover.all",
          "feature_visualize.all",
          "feature_dashboard.all",
          "feature_canvas.all",
          "feature_maps.all",
          "feature_infrastructure.all",
          "feature_logs.all",
          "feature_uptime.all",
          "feature_apm.read",
          "feature_graph.all",
          "feature_dev_tools.all",
          "feature_advancedSettings.all",
          "feature_indexPatterns.all",
          "feature_savedObjectsManagement.all",
          "feature_ingestManager.all",
          "feature_ml.all",
          "feature_observabilityCases.all"
        ],
        "resources" : [
          "space:sandbox"
        ]
      }
    ],
    "run_as" : [ ],
    "metadata" : { },
    "transient_metadata" : {
      "enabled" : true
    }
}
'

rolename="dcgs_site_user"
echo -en "\n${action} role: $rolename"
curl -XPUT -s -u "${username}":"${passwd}" https://${ES_HOST}:${ES_PORT}/_security/role/${rolename} -H "Content-Type: application/json" -d'
{
}
'

rolename="dcgs_cyan_admin"
echo -en "\n${action} role: $rolename"
curl -XPUT -s -u "${username}":"${passwd}" https://${ES_HOST}:${ES_PORT}/_security/role/${rolename} -H "Content-Type: application/json" -d'
{
    "cluster" : [ ],
    "indices" : [
      {
        "names" : [
          "cyan*"
        ],
        "privileges" : [
          "manage",
          "read",
          "maintenance",
          "view_index_metadata",
          "index",
          "read_cross_cluster"
        ],
        "field_security" : {
          "grant" : [
            "*"
          ],
          "except" : [ ]
        },
        "allow_restricted_indices" : false
      }
    ],
    "applications" : [
      {
        "application" : "kibana-.kibana",
        "privileges" : [
          "feature_discover.all",
          "feature_visualize.all",
          "feature_dashboard.all",
          "feature_canvas.all",
          "feature_maps.all",
          "feature_infrastructure.all",
          "feature_logs.all",
          "feature_uptime.all",
          "feature_siem.all",
          "feature_graph.all",
          "feature_dev_tools.all",
          "feature_advancedSettings.all",
          "feature_indexPatterns.all",
          "feature_savedObjectsManagement.all",
          "feature_ingestManager.all",
          "feature_ml.all"
        ],
        "resources" : [
          "space:cyber-analytics"
        ]
      }
    ],
    "run_as" : [ ],
    "metadata" : { },
    "transient_metadata" : {
      "enabled" : true
    }
}
'

rolename="dcgs_cyan_user"
echo -en "\n${action} role: $rolename"
curl -XPUT -s -u "${username}":"${passwd}" https://${ES_HOST}:${ES_PORT}/_security/role/${rolename} -H "Content-Type: application/json" -d'
{
    "cluster" : [ ],
    "indices" : [
      {
        "names" : [
          "cyan*"
        ],
        "privileges" : [
          "read"
        ],
        "field_security" : {
          "grant" : [
            "*"
          ],
          "except" : [ ]
        },
        "allow_restricted_indices" : false
      }
    ],
    "applications" : [
      {
        "application" : "kibana-.kibana",
        "privileges" : [
          "feature_dashboard.minimal_read",
          "feature_dashboard.url_create",
          "feature_dashboard.store_search_session",
          "feature_dashboard.generate_report",
          "feature_dashboard.download_csv_report"
        ],
        "resources" : [
          "space:cyber-analytics"
        ]
      }
    ],
    "run_as" : [ ],
    "metadata" : { },
    "transient_metadata" : {
      "enabled" : true
    }
}
'

rolename="dcgs_cyber_user"
echo -en "\n${action} role: $rolename"
curl -XPUT -s -u "${username}":"${passwd}" https://${ES_HOST}:${ES_PORT}/_security/role/${rolename} -H "Content-Type: application/json" -d'
{
    "cluster" : [ ],
    "indices" : [
      {
        "names" : [
          "dcgs-*"
        ],
        "privileges" : [
          "read",
          "view_index_metadata",
          "monitor",
          "read_cross_cluster"
        ],
        "field_security" : {
          "grant" : [
            "*"
          ],
          "except" : [ ]
        },
        "allow_restricted_indices" : false
      },
      {
        "names" : [
          ".alerts-security.alerts*",
          ".items-*",
          ".lists-*",
          ".siem-signals-*",
          ".preview.alerts-security.alerts-*"
        ],
        "privileges" : [
          "write",
          "read",
          "view_index_metadata",
          "maintenance"
        ],
        "field_security" : {
          "grant" : [
            "*"
          ]
        },
        "allow_restricted_indices" : false
      }
    ],
    "applications" : [
      {
        "application" : "kibana-.kibana",
        "privileges" : [
          "feature_siem.all"
        ],
        "resources" : [
          "*"
        ]
      }
    ],
    "run_as" : [ ],
    "metadata" : { },
    "transient_metadata" : {
      "enabled" : true
    }
}
'

rolename="stale-delete"
echo -en "\n${action} role: $rolename"
curl -XPUT -s -u "$username":"$passwd" https://elastic-node-1:9200/_security/role/${rolename} -H "Content-Type: application/json" -d'
{
	"cluster" : [ ],
	"indices" : [
		{
			"names" : [
				"dcgs-current-healthdata-*"
			],
			"privileges" : [
				"delete"
			],
			"field_security" : {
				"grant" : [
					"*"
				],
				"except" : [ ]
			},
			"allow_restricted_indices" : false
		}
	],
	"applications" : [ ],
	"run_as" : [ ],
	"metadata" : { },
	"transient_metadata" : {
		"enabled" : true
	}
}
'

echo -e "\n\n*** Script Complete ***"

#################################################################################
#
#			    Unclassified
#
#################################################################################
