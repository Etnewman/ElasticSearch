#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Install Elasticsearch Node
#
# Tracking #: CR-2020-OADCGS-086
#
# File name: installElasticNode.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2020-OADCGS-086, Steve Truxal, 2020-04-09: Original Version
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
# Frequency: During Elasticsearch initial installation
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
site=$(hostname -d | cut -f1 -d".")
clustername=${site^^}_Cluster
serviceAcct="$(hostname | cut -c 2,3)_elastic.svc"
cachain="cachain.pem"
certdir="/etc/elasticsearch/certs"
log4j="/etc/elasticsearch/log4j2.properties"

#
# Check to make sure we have PKI Certificates for this install
#
# Note:  The convention for naming elastic certificates is <hostname>.crt / <hostname>.key
#
function checkCerts() {

  # On a new install the PKI certificates for Elasticsearch must be put in place
  # verify certs exists on repo server
  elhost=$(hostname -f | cut -f1 -d".")
  fileloc="satrepo/pulp/content/oadcgs/Library/custom/Elastic_Client/Elastic_Files"
  # First check to make sure public cert is there
  status=$(curl --head --silent https://"$fileloc"/certs/"$elhost".crt | head -n 1)
  if ! echo "$status" | grep -q OK; then
    echo "Public certificate for $elhost not found on $fileloc, add to certs directory in elastic repo and run script again."
    exit
  fi

  # Next check to make sure private cert is there
  status=$(curl --head --silent https://"$fileloc"/certs/"$elhost".key | head -n 1)
  if echo "$status" | grep -q 404; then
    echo "Private key for $elhost not found on $fileloc, add to certs directory in elastic repo and run script again."
    exit
  fi
  # Next check to make sure root cert is there
  status=$(curl --head --silent https://"$fileloc"/certs/elastic_cachain.pem | head -n 1)
  if echo "$status" | grep -q 404; then
    echo "Root certificate not found on $fileloc, add to certs directory in elastic repo and run script again."
    exit
  fi
}

#
# Function to copy nodes PKI certificates
#
function getCerts() {
  # Create Directory for TLS certificates in elasticsearch folder created on installation
  if [ ! -d $certdir ]; then
    mkdir $certdir
  fi

  # Pull over certs and generate pkcs8 file for key
  elhost=$(hostname -f | cut -f1 -d".")
  fileloc="satrepo/pulp/content/oadcgs/Library/custom/Elastic_Client/Elastic_Files"
  curl --silent https://"$fileloc"/certs/"$elhost".crt >$certdir/"$elhost".crt
  curl --silent https://"$fileloc"/certs/"$elhost".key >$certdir/"$elhost".key
  # Get root CA from elastic install directory just incase root is different
  curl --silent https://"$fileloc"/certs/elastic_cachain.pem >$certdir/$cachain

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

  # initialize Variables
  master1="$(hostname | cut -c 1-9)"01
  master2="$(hostname | cut -c 1-9)"02
  master3="$(hostname | cut -c 1-9)"03

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

  case $numNodes in
  1)
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
  2)
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
  3)
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

cluster.initial_master_nodes:
  - $master1
  - $master2
  - $master3

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

#
# Function to create override file for elasticsearch service
#
function createOverride() {

  realmName=$(realm list --name-only)
  mkdir -p /etc/systemd/system/elasticsearch.service.d
  touch /etc/systemd/system/elasticsearch.service.d/override.conf
  cat <<EOF >/etc/systemd/system/elasticsearch.service.d/override.conf
[Service]
LimitMEMLOCK=infinity
TimeoutStartSec=180
User=$serviceAcct
ExecStartPre=/usr/local/sbin/refresh_tgt_tickets.sh -p $serviceAcct -r $realmName
EOF
  systemctl daemon-reload

}

#
# Function to create nodes data directory on NFS share
#
function createNodeDatadir() {

  # lets make sure the data directory for all elastic nodes is in place
  datadir_exists=$(runuser -l "$serviceAcct" -c "if [ -d /$1/$clustername ]; then echo true; fi")

  if [ "$datadir_exists" != "true" ]; then
    #data directory does not exist so create it
    runuser -l "$serviceAcct" -c "mkdir /$1/$clustername"
    echo "Created $clustername Directory "
  fi

  # Now lets make sure the data directory for this specific node exists
  myhost=$(hostname)
  datadir_exists=$(runuser -l "$serviceAcct" -c "if [ -d /$1/$clustername/$myhost ]; then echo true; fi")

  if [ "$datadir_exists" != "true" ]; then
    # nodes data directory does not exist so create it
    runuser -l "$serviceAcct" -c "mkdir /$1/$clustername/$myhost"
    echo "Created $clustername/$myhost Directory "
  fi

  # lets make sure the archive directory is in place
  # This will be done one every run but is harmless if the directory already exists
  archiveDir="elasticArchive"
  datadir_exists=$(runuser -l "${serviceAcct}" -c "if [ -d /$1/${archiveDir} ]; then echo true; fi")

  if [ "$datadir_exists" != "true" ]; then
    #data directory does not exist so create it
    runuser -l "${serviceAcct}" -c "mkdir /$1/${archiveDir}"
    echo "Created ${archiveDir} directory."
  else
    echo "${archiveDir} directory already exits."
  fi

}

#
# function to verify needed mount points exist
#
function checkMounts() {

  # Check to make sure we have an /ELK mount point
  if ! mountpoint -q /ELK-nfs; then
    echo "Error - No /ELK-nfs mount point please check fstab..."
    echo "Note: All Elastic nodes should have an /ELK-nfs mount point to the Isilon"
    exit
  fi

  if [ "$dataLoc" == 1 ]; then
    if [[ ! -d /ELK-local ]]; then
      echo "Error - Local storge Selected but No /ELK-local directory..."
      echo "Note:  If this host has a 2nd disk then /ELK-Local should be a mount point"
      exit
    fi
    # Ensure data path is owned by service account
    chown -R "$serviceAcct" /ELK-local
  fi
}

#
# function to update tmpfiles.d elasticsearch.conf file with correct user
#
function updateTmpfilesd() {

  sed -i "s/elasticsearch elasticsearch/${serviceAcct} elasticsearch/g" /usr/lib/tmpfiles.d/elasticsearch.conf

}

#
# function to adjust tmp directory for Java Native Access(JNA)
#
function updateJNAtmpdir() {

  mkdir /var/lib/elasticsearch/tmp
  chown -R "$serviceAcct" /var/lib/elasticsearch
  sed -i "s/#ES_JAVA_OPTS=/ES_JAVA_OPTS=\"-Djna.tmpdir=\/var\/lib\/elasticsearch\/tmp\"/g" /etc/sysconfig/elasticsearch

}

####################
# Main begins here #
####################
echo
echo "*** NOTICE *** "
echo "This script will install an elasticsearch node..."
echo
read -p "Would you like to proceed with the installation? <y/n> " -n 1 -r </dev/tty
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborting script..."
  exit 1
fi

numNodes=0
while [[ ($numNodes -lt 1 || $numNodes -gt 3) ]]; do
  echo "How many Elasticsearch nodes will there be in this cluster?"
  echo "Options:"
  echo "   Enter 1 for 7 Nodes"
  echo "   Enter 2 for 10 Nodes"
  echo "   Enter 3 for 15 Nodes"
  read -p "Enter a value (1-3): " -r numNodes </dev/tty
  echo
done

dataLoc=0
while [[ ($dataLoc -lt 1 || $dataLoc -gt 2) ]]; do
  echo "Where will data for this node be stored? "
  echo "  Enter 1 for locally stored in /ELK-local"
  echo "  Enter 2 for remote storage via NFS using the /ELK-nfs mount point"
  read -p "Enter a value (1 or 2): " -r dataLoc </dev/tty
  echo
done

# Check to see if we are doing new install or upgrade
# Note: If upgrade direct to use upgrade_node script
#
if systemctl list-units --type=service -all | grep -Fq elasticsearch; then
  echo "Error - Elasticsearch service is already installed, please use the upgrade_node script for upgrades..."
  exit
fi

checkMounts

# On a new install the initial keystore containing the bootstrap.password is needed so lets
# verify initial keystore exists on repo server
fileloc="satrepo/pulp/content/oadcgs/Library/custom/Elastic_Client/Elastic_Files"
status=$(curl --head --silent https://"$fileloc"/install/elasticsearch.keystore | head -n 1)
if ! echo "$status" | grep -q OK; then
  echo "Initial keystore for elastic not found on repo server, add to install directory in elastic repo to continue."
  exit
fi

echo "This script will preform a new install of elasticsearch..."
checkCerts
yum -y install elasticsearch

# Pull over the initial keystore containing the bootstrap.password for elasticsearch
curl --silent https://"$fileloc"/install/elasticsearch.keystore >/etc/elasticsearch/elasticsearch.keystore
getCerts

# make sure service is enabled
systemctl enable elasticsearch

# make sure service account owns directies so it can run elastic
chown -R "$serviceAcct" /etc/elasticsearch
chown -R "$serviceAcct" /var/log/elasticsearch
chmod 755 /var/log/elasticsearch

updateJNAtmpdir

# If remote data then create data directory for node
if [ "$dataLoc" == "2" ]; then
  createNodeDatadir "ELK-nfs"
fi

# Create override file to run as service account
createOverride

# Create elastic yml configuration file
createElasticyml "$numNodes" "$dataLoc"

# Ensure log4j is correct
curl -k --silent https://"$fileloc"/install/artifacts/log4j2.properties.elasticsearch -o $log4j
chmod 644 $log4j

# Make sure user in tmpfiles.d elasticsearch.conf is service account
updateTmpfilesd

echo "Elasticsearch node installation finished"
#################################################################################
#
#			    Unclassified
#
#################################################################################
