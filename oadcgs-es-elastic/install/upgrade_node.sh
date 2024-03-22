#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Convenience script used to execute python script for upgrading
#          an Elastic node
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: upgrade_node.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, date it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Steve Truxal, 2021-03-08: Original Version
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
hub=$(hostname | cut -c 1-3)
fileloc="satrepo/pulp/content/oadcgs/Library/custom/Elastic_Client/Elastic_Files"
log4j="/etc/elasticsearch/log4j2.properties"
user=$SUDO_USER
ES_HOST=elastic-node-1
ES_PORT=9200
kibanaYML="/etc/kibana/kibana.yml"
serviceAcct="$(hostname | cut -c 2,3)_elastic.svc"

#
# Function to create override file for Kibana service and sets StanardOutput to null
#
function createKibanaOverride() {

  case $1 in
  7)
    es1=1
    es2=2
    es3=3
    ;;
  10 | 15)
    es1=6
    es2=7
    es3=8
    ;;
  *)
    echo "Unsupported Cluster size for DCGS: $1"
    exit
    ;;
  esac

  mkdir -p /etc/systemd/system/kibana.service.d
  touch /etc/systemd/system/kibana.service.d/override.conf
  cat <<EOF >/etc/systemd/system/kibana.service.d/override.conf
[Service]
StandardOutput=null
Environment="ESHOST1=https://elastic-node-${es1}:9200"
Environment="ESHOST2=https://elastic-node-${es2}:9200"
Environment="ESHOST3=https://elastic-node-${es3}:9200"
EOF
  systemctl daemon-reload
}

#
# Function to create elasticsearch yml file
#
function createElasticyml() {

  # Create elasticsearch.yml file for this node
  #

  #
  # Backup original
  echo "Backing up original elasticsearch.yml file"
  if [ ! -f /etc/elasticsearch/elasticsearch.yml.UPG_"$(date +%m%d%y)" ]; then
    cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.UPG_"$(date +%m%d%y)"
  fi

  #
  # Delete backups older than 6 months
  #
  echo "Deleting old backups"
  find /etc/elasticsearch -type f -name "elasticsearch.yml.UPG*" -mtime +180 -delete

  cachain="cachain.pem"
  certdir="/etc/elasticsearch/certs"
  realmName=$(realm list --name-only)
  domainController_1="${hub}sm00dc01.${realmName}:636"
  domainController_2="${hub}sm00dc02.${realmName}:636"
  site=$(hostname -d | cut -f1 -d".")
  clustername=${site^^}_Cluster
  node=$(hostname | cut -c 10,11)
  node_roles=""
  repopath=/ELK-nfs/elasticArchive

  case $1 in
  7)
    echo "7 node cluster"
    # Set correct attributes for node in 7 node cluster
    # Current configuration:
    # Node  1     : Master/Machine Learning/Hot Data/Ingest/Data
    # Nodes 2-3   : Master/Machine Learning/Hot Data/Ingest/Data/Transform
    # Nodes 4-6   : Warm Data/Ingest/Cold Data
    # Node 7 : Frozen
    case $node in
    01)
      echo "Master node(roles-mlhis)"
      node_roles="master, ml, ingest, data_hot, data_content"
      datapath="/ELK-local"
      ;;
    02 | 03)
      echo "Master node(roles-mhis)"
      node_roles="master, ml, ingest, data_hot, data_content, transform"
      datapath="/ELK-local"
      ;;
    04 | 05 | 06)
      echo "Warm Data Node"
      node_roles="ingest, data_warm, data_cold"
      datapath="/ELK-nfs/$clustername/\${HOSTNAME}"
      ;;
    07)
      echo "Frozen Data Node"
      node_roles="data_frozen"
      datapath="/ELK-local"
      ;;
    esac
    ;;
  10)
    echo "10 node cluster"
    # Set correct attributes for node in 10 node cluster
    # Current configuration:
    # Nodes 1-3   : Master, Remote Cluster Client
    # Nodes 4     : Machine Learning/Data Content, Transform, Remote Cluster Client
    # Nodes 5-6   : Hot Data Nodes, Ingest, Data Content, Remote Cluster Client
    # Nodes 7-9   : Warm Data Nodes, Ingest, Cold Data, Remote Cluster Client
    # Node 10     : Frozen Node
    case $node in
    01 | 02 | 03)
      echo "Master node"
      node_roles="master, remote_cluster_client"
      datapath="/ELK-local"
      ;;
    04)
      echo "ML node"
      node_roles="ml, data_content, transform, remote_cluster_client"
      datapath="/ELK-local"
      ;;
    05 | 06)
      echo "Hot Data Node"
      node_roles="ingest, data_hot, data_content, remote_cluster_client"
      datapath="/ELK-local"
      ;;
    10)
      echo "Frozen Data Node"
      node_roles="data_frozen"
      datapath="/ELK-local"
      ;;
    *)
      echo "Warm Data Node"
      node_roles="ingest, data_warm, data_cold, remote_cluster_client"
      datapath="/ELK-nfs/$clustername/\${HOSTNAME}"
      ;;
    esac
    ;;
  15)
    echo "15 node cluster"
    # Set correct attributes for node in 15 node cluster
    # Current configuration:
    # Nodes 1-3   : Master, Remote Cluster Client
    # Nodes 4-5   : Machine Learning/Data Content, Transform, Remote Cluster Client
    # Nodes 6-9   : Hot Data Nodes, Ingest, Data Content, Remote Cluster Client
    # Nodes 10-14 : Warm Data Nodes, Ingest, Cold Data, Remote Cluster Client
    # Node 15     : Frozen Node
    case $node in
    01 | 02 | 03)
      echo "Master node"
      node_roles="master, remote_cluster_client"
      datapath="/ELK-local"
      ;;
    04 | 05)
      echo "ML/Ingest node"
      node_roles="ml, data_content, transform, remote_cluster_client"
      datapath="/ELK-local"
      ;;
    06 | 07 | 08 | 09)
      echo "Hot Data Node"
      node_roles="ingest, data_hot, data_content, remote_cluster_client"
      datapath="/ELK-local"
      ;;
    15)
      echo "Frozen Data Node"
      node_roles="data_frozen"
      datapath="/ELK-local"
      ;;
    *)
      echo "Warm Data Node"
      node_roles="ingest, data_warm, data_cold, remote_cluster_client"
      datapath="/ELK-nfs/$clustername/\${HOSTNAME}"
      ;;
    esac
    ;;
  *)
    echo "Elasticsearch.yml not updated"
    echo "Unsupported Cluster size for DCGS"
    echo "Please verify Elastic Cluster status is Green and all nodes are healthy"
    echo "Please re-run script once verified"
    exit
    ;;
  esac

  # Create file
  cat <<EOF >/etc/elasticsearch/elasticsearch.yml
bootstrap.memory_lock: true
path.data: $datapath
path.logs: /var/log/elasticsearch

cluster.name: $clustername
node.name: ${HOSTNAME}

path.repo:
  - $repopath
node.roles: [ $node_roles ]
xpack.ml.enabled: true


network.host: _site:ipv4_
discovery.seed_hosts: [ elastic-node-2, elastic-node-3 ]
xpack:
  security:
    audit.enabled : true
    enabled: true
    authc:
      realms:
        native:
          native1:
            order: 0
        active_directory:
          oa_active_diretory:
            order: 1
            domain_name: $realmName
            url: ldaps://$domainController_1, ldaps://$domainController_2
            load_balance.type: round_robin
            ssl:
              certificate_authorities: ["$certdir/$cachain"]
              verification_mode: none
    transport:
      ssl.enabled: true
      ssl.verification_mode: certificate
      ssl.key: $certdir/\${HOSTNAME}.key
      ssl.certificate: $certdir/\${HOSTNAME}.crt
      ssl.certificate_authorities: [ "$certdir/$cachain" ]
    http:
      ssl.enabled: true
      ssl.verification_mode: certificate
      ssl.key: $certdir/\${HOSTNAME}.key
      ssl.certificate: $certdir/\${HOSTNAME}.crt
      ssl.certificate_authorities: [ "$certdir/$cachain" ]

indices.recovery.max_concurrent_snapshot_file_downloads: 1
EOF

  #
  # End elasticsearch.yml
  #
}

## Main ##

#Upgrading variables line
package="elasticsearch"
SUB="No matching Packages"

#Checks for available updates for elasticsearch on the system
eVerCheck=$(yum list available $package 2>&1)
upgradable=$(echo "$eVerCheck" | grep "$SUB")

read -sp "User <$user> will be used to upgrade node $user: " -r passwd </dev/tty
echo

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

# Upgrading configuration files to ensure correctness
echo "Upgrading elasticsearch configuration files..."

# Determine number of nodes in the cluster
numNodes=$(curl -sk -u "${user}":"${passwd}" https://${ES_HOST}:${ES_PORT}/_cat/nodes | wc -l)
#
# Run function to edit elasticsearch.yml
#
createElasticyml "$numNodes"

# Ensure timeout is in override file
ELOverride="/etc/systemd/system/elasticsearch.service.d/override.conf"
sed -i -n -e '/^TimeoutStartSec=/!p' -e '/User/a TimeoutStartSec=180' $ELOverride
systemctl daemon-reload

if [ ! "$upgradable" ]; then
  upgradeVer=$(echo "$eVerCheck" | grep "$package" | awk '{print $2}' | cut -d'-' -f1)
  echo "New $package version ($upgradeVer) available, executing upgrade script."

  # remove jvm.options.rpmnew if it exists before upgrade
  #
  if [ -f /etc/elasticsearch/jvm.options.rpmmew ]; then
    rm /etc/elasticsearch/jvm.options.rpmmew
  fi

  # Clear logs on this upgrade
  mv /var/log/elasticsearch /var/log/elasticsearch.backup
  mkdir /var/log/elasticsearch
  chown "$serviceAcct":elasticsearch /var/log/elasticsearch
  chmod 755 /var/log/elasticsearch

  # Ensure python requests module is installed
  yum -y install python-requests

  # pull upgrade python script over to /tmp
  #
  curl -k --silent https://"$fileloc"/install/upgrade.py >/tmp/upgrade.py

  python /tmp/upgrade.py -u "${user}" -p "${passwd}" "$1"

  rm /tmp/upgrade.py

  #
  # Ensure we are using latest jvm.options
  #
  if [ -f /etc/elasticsearch/jvm.options.rpmnew ]; then
    mv /etc/elasticsearch/jvm.options.rpmnew /etc/elasticsearch/jvm.options
  fi

else
  curVer=$(rpm -qa $package | cut -f2 -d"-")
  echo "$package is running the latest available version($curVer), no software upgrade will be performed. Please restart Elasticsearch manually to update log4j2"

fi

# pull metricbeat.keystore
#
curl -k --silent https://"$fileloc"/keystores/metricbeat.keystore -o /var/lib/metricbeat/metricbeat.keystore
chmod 600 /var/lib/metricbeat/metricbeat.keystore

#
# Ensure directory permissions are correct for service account
#
chown -R "$serviceAcct":elasticsearch /etc/elasticsearch

#
# Ensure kibana override exists eliminating duplicate log output to /var/log/messages
#
# Make sure this runs only on kibana
#
if [ -s "$kibanaYML" ]; then
  createKibanaOverride "$numNodes"
fi

# Ensure log4j is correct
curl -k --silent https://"$fileloc"/install/artifacts/log4j2.properties.elasticsearch -o $log4j
chmod 644 $log4j

#
# Delete backup elasticsearch log directory
#
rm -rf /var/log/elasticsearch.backup

echo "Upgrade Node script complete"
#################################################################################
#
#			    Unclassified
#
#################################################################################
