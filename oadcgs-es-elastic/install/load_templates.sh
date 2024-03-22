#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Loads templates into Elastic
#
# Tracking #: CR-2020-OADCGS-086
#
# File name: load_templates.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, date it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2020-OADCGS-086, Steve Truxal, 2020-07-21: Original Version
#   v1.01, CR-2020-OADCGS-086, Steve Truxal, 2022-01-20: update for Upgrades
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

fileloc="satrepo/pulp/content/oadcgs/Library/custom/Elastic_Client/Elastic_Files"
user=$SUDO_USER

echo
echo "Determining version..."
if [ ! -f "/usr/share/elasticsearch/bin/elasticsearch" ]; then
  echo "This script must be run from an Elasticsearch node..."
  exit 1
fi

# Lets figure out the version to bootstrap based on version of installed elasticsearch
esver=$(/usr/share/elasticsearch/bin/elasticsearch --version | /bin/cut -f2 -d' ' | /bin/sed 's/.$//')

if [ -z "$esver" ]; then
  echo
  echo "*** ERROR *** "
  echo "Unable to determine elasticsearch version, this script must be run on an elasticsearch node..."
  echo
  exit 1
fi

echo
read -sp "User <$user> will be used to store templates in elastic, please enter the password for $user: " -r passwd </dev/tty

#
# This is an array of all index templates to be loaded
#

index_templates=(
  esti_catalyst
  esti_datadomain
  esti_fc6xx
  esti_fx2
  esti_isilon
  esti_nexus5k
  esti_nexus7k
  esti_r6xx
  esti_xtremio
  esti_healthdata
  esti_current-healthdata
  esti_idm
  esti_sccmdb
  esti_hbss-epo
  esti_hbss-metrics
  esti_hbss-dlp
  esti_sqlserver
  esti_eracent
  esti_puppet
  esti_vsphere
  esti_filebeat-"${esver}"
  esti_db_postgres
  esti_heartbeat-"${esver}"
  esti_winlogbeat-"${esver}"
  esti_iptables
  esti_serena
  esti_render
  esti_soaesb
  esti_acas
  esti_socetgxp
  esti_gxpxplorer
  esti_maas_logs
  esti_loginsight_syslog
  esti_logindata
  esti_ecp
  esti_ashes
  esti_unparsable-syslog
)

#
# This is an array of all component templates to be loaded
#
comp_templates=(
  estc_dcgs_defaults
  estc_dcgs_app_defaults
  estc_ciscoswitch-mappings
  estc_datadomain-mappings
  estc_dellidrac-mappings
  estc_fx2-mappings
  estc_isilon-mappings
  estc_xtremio-mappings
  estc_healthdata-mappings
  estc_idm-mappings
  estc_sccmdb-mappings
  estc_hbss-epo-mappings
  estc_hbss-metrics-mappings
  estc_hbss-epo_dlp-mappings
  estc_sqlserver-mappings
  estc_syslog-mappings
  estc_eracent-mappings
  estc_puppet-mappings
  estc_vsphere-mappings
  estc_db_postgres-mappings
  estc_filebeat-"${esver}"-mappings
  estc_heartbeat-"${esver}"-mappings
  estc_winlogbeat-"${esver}"-mappings
  estc_metricbeat-"${esver}"-mappings
  estc_audits_syslog-mappings
  estc_iptables-mappings
  estc_serena-mappings
  estc_render-mappings
  estc_soaesb-mappings
  estc_acas-mappings
  estc_socetgxp-mappings
  estc_gxpxplorer-mappings
  estc_maas_logs-mappings
  estc_loginsight-agent-mappings
  estc_loginsight_syslog-mappings
  estc_logindata-mappings
  estc_audits_syslog-settings
  estc_db-settings
  estc_hbss-epo-settings
  estc_syslog-settings
  estc_vsphere-settings
  estc_winlogbeat-settings
  estc_ecp-mappings
  estc_ashes-mappings
)

#
# This is an array of all legacy templates to be deleted
#
del_templates=(est_arcsight-udp est_idm-template est_sccmdb est_hbss-syslog est_loginsight est_sqlserver est_linux-syslog)

#
# pull each component template from the satellite server and load into kibana
#
echo
for template in "${comp_templates[@]}"; do
  printf "\nputting template: %s" "$template"

  curl --silent https://"$fileloc"/install/templates/"${template}" >/tmp/"${template}"

  curl -k -XPUT -u "${user}":"${passwd}" https://elastic-node-1:9200/_component_template/"${template}" -H 'Content-Type: application/json' -d@/tmp/"${template}"

  rm /tmp/"${template}"
done

#
# pull each index template from the satellite server and load into kibana
#
for template in "${index_templates[@]}"; do
  printf "\nputting template: %s" "$template"

  curl --silent https://"$fileloc"/install/templates/"${template}" >/tmp/"${template}"

  curl -k -XPUT -u "${user}":"${passwd}" https://elastic-node-1:9200/_index_template/"${template}" -H 'Content-Type: application/json' -d@/tmp/"${template}"

  rm /tmp/"${template}"
done

#
# Remove legacy templates
#
for template in "${del_templates[@]}"; do

  printf "\nDeleting template: %s, if it exists" "$template"
  curl --silent --output /dev/null -XDELETE -u "${user}":"${passwd}" https://elastic-node-1:9200/_template/"${template}"

done

# Ensure old templates are removed
curl --silent --output /dev/null -XDELETE -u "${user}":"${passwd}" https://elastic-node-1:9200/_index_template/esti_idm-template
curl --silent --output /dev/null -XDELETE -u "${user}":"${passwd}" https://elastic-node-1:9200/_index_template/esti_linux-syslog
curl --silent --output /dev/null -XDELETE -u "${user}":"${passwd}" https://elastic-node-1:9200/_index_template/esti_hbss-syslog
curl --silent --output /dev/null -XDELETE -u "${user}":"${passwd}" https://elastic-node-1:9200/_index_template/esti_arcsight-udp
curl --silent --output /dev/null -XDELETE -u "${user}":"${passwd}" https://elastic-node-1:9200/_index_template/esti_loginsight
curl --silent --output /dev/null -XDELETE -u "${user}":"${passwd}" https://elastic-node-1:9200/_index_template/esti_syslog

curl --silent --output /dev/null -XDELETE -u "${user}":"${passwd}" https://elastic-node-1:9200/_component_template/esti_idm-template-mappings
curl --silent --output /dev/null -XDELETE -u "${user}":"${passwd}" https://elastic-node-1:9200/_component_template/estc_linux-syslog-mappings
curl --silent --output /dev/null -XDELETE -u "${user}":"${passwd}" https://elastic-node-1:9200/_component_template/estc_arcsight-udp-mappings
curl --silent --output /dev/null -XDELETE -u "${user}":"${passwd}" https://elastic-node-1:9200/_component_template/estc_hbss-syslog-mappings
curl --silent --output /dev/null -XDELETE -u "${user}":"${passwd}" https://elastic-node-1:9200/_component_template/estc_loginsight-mappings

echo
echo
echo "Templates loaded."
echo
echo
#################################################################################
#
#			    Unclassified
#
#################################################################################
