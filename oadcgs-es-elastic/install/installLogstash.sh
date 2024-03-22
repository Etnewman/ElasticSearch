#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Installation script for Logstash instance
#
# Tracking #: CR-2020-OADCGS-086
#
# File name: installLogstash.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, date it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2020-OADCGS-086, Steve Truxal, 2020-04-13: Original Version
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

###############################################################
#
# Note: Not all pipelines are inabled during the initial install.  Additional pipelines are added
#       while following the installation procedures for Elastic

elasticpw="elastic"
pkcs8pw="elastic"
newKeystore="false"
cachain="cachain.pem"
certdir="/etc/logstash/certs"
lshost=$(hostname -f | cut -f1 -d".")
log4j="/etc/logstash/log4j2.properties"
logsysconfig="/etc/sysconfig/logstash"
dnsDom=$(hostname -d)
fileloc="satrepo/pulp/content/oadcgs/Library/custom/Elastic_Client/Elastic_Files"
snum=$(hostname | cut -c 2-3)
ES_HOST="elastic-node-1"
ES_PORT="9200"
user="elastic"
passwd=$elasticpw
mssqljdbcver="7.2.2"
postgresqlver="42.3.1"

# Function: getsitesyml
# Parameters: None
# Desc: pull sites.yml file to /tmp to update siteloc
function getsitesyml() {
  curl --silent https://"$fileloc"/install/sites.yml >/tmp/sites.yml
  siteloc=$(sed 's/ *//g' /tmp/sites.yml | grep ^"$snum" | cut -d: -f2)
  rm /tmp/sites.yml
}

#
# Check to make sure we have PKI Certificates for this install
#
# Note:  The convention for naming elastic certificates is <hostname>.crt / <hostname>.key
#
function checkCerts() {

  # On a new install the PKI certificates for Logstash must be put in place
  # verify initial keystore exists on repo server
  fileloc="satrepo/pulp/content/oadcgs/Library/custom/Elastic_Client/Elastic_Files"
  # First check to make sure public cert is there
  status=$(curl --head --silent https://"$fileloc"/install/certs/"$lshost".crt | head -n 1)
  echo "$status"
  if ! echo "$status" | grep -q OK; then
    echo "Public certificate for $lshost not found on $fileloc, add to install/certs directory in elastic repo and run script again."
    exit
  fi

  # Next check to make sure private cert is there
  status=$(curl --head --silent https://"$fileloc"/install/certs/"$lshost".key | head -n 1)
  echo "$status"
  if echo "$status" | grep -q 404; then
    echo "Private key for $lshost not found on $fileloc, add to install/certs directory in elastic repo and run script again."
    exit
  fi
  # Next check to make sure root cert is there
  status=$(curl --head --silent https://"$fileloc"/install/certs/elastic_cachain.pem | head -n 1)
  if echo "$status" | grep -q 404; then
    echo "Root certificate not found on $fileloc, add to install/certs directory in elastic repo and run script again."
    exit
  fi
}

#
# Function to copy nodes PKI certificates
#
function getCerts() {
  # Create Directory for TLS certificates in logstash folder created on installation
  mkdir /etc/logstash/certs

  # Pull over certs and generate pkcs8 file for key
  lshost=$(hostname -f | cut -f1 -d".")
  fileloc="satrepo/pulp/content/oadcgs/Library/custom/Elastic_Client/Elastic_Files"
  curl --silent https://"$fileloc"/install/certs/"$lshost".crt >$certdir/"$lshost".crt
  curl --silent https://"$fileloc"/install/certs/"$lshost".key >$certdir/"$lshost".key
  # Get root CA from elastic install directory just incase root is different
  curl --silent https://"$fileloc"/install/certs/elastic_cachain.pem >$certdir/$cachain
  # ***** Is the private key password protected on production??  ****
  openssl pkcs8 -topk8 -in /etc/logstash/certs/"$lshost".key -out /etc/logstash/certs/"${lshost}"_pkcs8.key -passout pass:$pkcs8pw

}

#
# Function to update amount of memory for JVM heap
#
function updateJvmOptions() {

  # Begin jvm.options
  #
  # Update JVM options based on memory allocation of this node
  # -- Give half of memory to JVM --
  # Note: this will only work after the initial install, if memory
  #       on this node is expanded the jvm.options file will have
  #       to be manually updated.

  mem=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  mem=$((mem / 1024 / 1024))

  # if more than 60GB of ram only give 30GB to JVM
  # otherwise give half
  if [ "$mem" -gt 60 ]; then
    mem=30
  else
    mem=$((mem / 2 + 1))
  fi

  sed -i "s/-Xms1g/-Xms${mem}g/g" /etc/logstash/jvm.options
  sed -i "s/-Xmx1g/-Xmx${mem}g/g" /etc/logstash/jvm.options

  #
  # End jvm.options
  #
}

#
# Function used to setup initial yml, this is needed
# to create the keystore
function inityml() {

  cat <<EOF >/etc/logstash/logstash.yml
node.name: $lshost
path.data: /var/lib/logstash
path.logs: /var/log/logstash
EOF

}

################################################################
#
# Function: Bootstrap Logstash users
#
# Desc: This funtion will create roles and users used by logstash
#
#
###############################################################
function bootstrapLogstashUsers() {

  echo "Bootstrapping Logstash users..."

  ###### Bootstrap users
  # Generate random password for logstash_system  user
  logsysUser=$(tr -cd '[:alnum:]' </dev/urandom | fold -w15 | head -n1)
  curl -k -u "${user}":"${passwd}" -XPUT -H 'Content-Type: application/json' "https://${ES_HOST}.${clusterSite}:${ES_PORT}/_xpack/security/user/logstash_system/_password" -d' {"password":'\""$logsysUser"\"'}'

  curl -k -u "${user}":"${passwd}" -XPUT -H 'Content-Type: application/json' "https://${ES_HOST}.${clusterSite}:${ES_PORT}/_xpack/security/role/logstash_writer" -d '
{
  "cluster":
 ["manage_index_templates", "monitor", "manage_ilm"],
  "indices":
 [
    {
      "names":
 [ "logstash-*","*" ],
      "privileges":
 ["write","create","delete","create_index","manage","manage_ilm"]
    }
  ]
}'

  # create logstash_internal user with random password
  logIntUser=$(tr -cd '[:alnum:]' </dev/urandom | fold -w15 | head -n1)
  curl -k -u "${user}":"${passwd}" -XPUT -H 'Content-Type: application/json' "https://${ES_HOST}.${clusterSite}:${ES_PORT}/_xpack/security/user/logstash_internal" -d '{"password":'\""$logIntUser"\"',"roles":["logstash_writer"],"full_name":"Internal Logstash User"}'

  # create logstash_admin_user with random password
  logAdminUser=$(tr -cd '[:alnum:]' </dev/urandom | fold -w15 | head -n1)
  curl -k -u "${user}":"${passwd}" -XPUT -H 'Content-Type: application/json' "https://${ES_HOST}.${clusterSite}:${ES_PORT}/_xpack/security/user/logstash_admin_user" -d '{"password":'\""$logAdminUser"\"',"roles":["logstash_writer","logstash_admin"],"full_name":"Logstash Admin User"}'

  ######  Now lets save our passwords in the logstash keystore

  # need a basic yml file to setup keystore
  inityml

  if [ ! -f /etc/logstash/logstash.keystore ]; then
    echo "Creating logstash keystore..."
    echo y | /usr/share/logstash/bin/logstash-keystore create --path.settings /etc/logstash >>/dev/null
  fi

  echo
  # Add xpack.monitoring.elasticsearch.password to keystore
  echo "Adding ES_MON_PASSWORD to keystore..."
  /usr/share/logstash/bin/logstash-keystore remove ES_MON_PASSWORD --stdin --path.settings /etc/logstash >>/dev/null
  echo "$logsysUser" | /usr/share/logstash/bin/logstash-keystore add ES_MON_PASSWORD --stdin --path.settings /etc/logstash >>/dev/null

  # Add Logstash output user "logstash_internal" password to keystore
  echo "Adding LOGSTASH_WRITER to keystore..."
  /usr/share/logstash/bin/logstash-keystore remove LOGSTASH_WRITER --stdin --path.settings /etc/logstash >>/dev/null
  echo "$logIntUser" | /usr/share/logstash/bin/logstash-keystore add LOGSTASH_WRITER --stdin --path.settings /etc/logstash >>/dev/null

  echo "Adding ES_MAN_PASSWORD to keystore..."
  # Add xpack.management.elasticsearch.password to keystore
  /usr/share/logstash/bin/logstash-keystore remove ES_MAN_PASSWORD --stdin --path.settings /etc/logstash >>/dev/null
  echo "$logAdminUser" | /usr/share/logstash/bin/logstash-keystore add ES_MAN_PASSWORD --stdin --path.settings /etc/logstash >>/dev/null

  echo "Adding SSL_PASSPHRASE to keystore..."
  # Add password to decrypt pkcs8 key
  /usr/share/logstash/bin/logstash-keystore remove SSL_PASSPHRASE --stdin --path.settings /etc/logstash >>/dev/null
  echo $pkcs8pw | /usr/share/logstash/bin/logstash-keystore add SSL_PASSPHRASE --stdin --path.settings /etc/logstash >>/dev/null

}

#
# function used to determine if a user exists in elastic
#
function userExistsinKibana() {

  user=$(curl -ks -u "${user}":"${passwd}" "https://${ES_HOST}.${clusterSite}:${ES_PORT}/_security/user/$1")
  if [ "$user" == "{}" ]; then echo "false"; else echo "true"; fi

}

#
# function used to determine if a role exists in elastic
#
function roleExistsinKibana() {

  role=$(curl -ks -u "${user}":"${passwd}" "https://${ES_HOST}.${clusterSite}:${ES_PORT}/_security/role/$1")
  if [ "$role" == "{}" ]; then echo "false"; else echo "true"; fi

}

#
# function used to notify user to copy keystore to repo server
#
function notifyCopy() {
  # Notify installer to copy keystore to repo server
  echo
  echo "     ******************* IMPORTANT NOTICE ********************************"
  echo "     *                                                                   *"
  echo "     * Logstash Keystore created during installation .                   *"
  echo "     *                                                                   *"
  echo "     * You MUST Copy:                                                    *"
  echo "     *                                                                   *"
  echo "     *    /etc/logstash/logstash.keystore                                *"
  echo "     *                                                                   *"
  echo "     * from this machine to:                                             *"
  echo "     *                                                                   *"
  echo "     *    $fileloc/keystores/logstash.keystore                           *"
  echo "     *                                                                   *"
  echo "     * To allow installation of other Logstash instances                 *"
  echo "     *                                                                   *"
  echo "     ******************* IMPORTANT NOTICE ********************************"
  echo
}

#
# This function is to setup the logstash.keystore.  If this is the initial logstash
# instance for this cluster then the bootstrapLogstashUsers function will be called
# to create the needed users/roles and keystore.  If this is not the initial logstash
# instance forthis cluster the keystore will be copied from the repo server.
#
function SetupKeystore() {

  if [ $newKeystore == "true" ]; then
    echo "Logstash users/roles do not exist in Kibana, creating and adding to logstash.keystore"
    bootstrapLogstashUsers
    notifyCopy
  else
    # Copy over logstash.keystore
    curl --silent https://"$fileloc"/keystores/logstash.keystore >/etc/logstash/logstash.keystore
  fi
}

# Function: latestjdbc
# Parameters: None
# Desc: Pull over latest jdbc drivers
function latestjdbc() {

  # Ensure jdbc directory exists
  mkdir /etc/logstash/jdbc
  chown logstash /etc/logstash/jdbc

  if [ ! -f /etc/logstash/jdbc/mssql-jdbc-${mssqljdbcver}.jre8.jar ]; then
    curl -k --silent https://"$fileloc"/install/jdbc/mssql-jdbc-${mssqljdbcver}.jre8.jar >/etc/logstash/jdbc/mssql-jdbc-${mssqljdbcver}.jre8.jar
  else
    echo "Latest mssql-jdbc-${mssqljdbcver}.jre8.jar already on system"
  fi

  if [ ! -f /etc/logstash/jdbc/postgresql-${postgresqlver}.jar ]; then
    curl -k --silent https://"$fileloc"/install/jdbc/postgresql-${postgresqlver}.jar >/etc/logstash/jdbc/postgresql-${postgresqlver}.jar
  else
    echo "Latest postgresql-${postgresqlver}.jar already on system"
  fi

  chown logstash /etc/logstash/jdbc/mssql-jdbc-${mssqljdbcver}.jre8.jar
  chown logstash /etc/logstash/jdbc/postgresql-${postgresqlver}.jar
}

#
# function to add needed enviornment variables to logstasy sysconfig file
#
function addSysconfig() {

  site=$(hostname | cut -c 1-3)
  snum=$(hostname | cut -c 2-3)
  site=${site^^}

  # If the site doesn't exist set it to UNKNOWN
  if [ -z "$siteloc" ]; then
    siteloc="UNKNOWN"
  fi

  case $1 in
  1)
    out1=1
    out2=2
    out3=3
    ;;
  2)
    out1=5
    out2=6
    out3=7
    ;;
  3)
    out1=6
    out2=7
    out3=8
    ;;
  *)
    echo "Unsupported Cluster size for DCGS: $1"
    exit
    ;;
  esac

  cat <<EOF >$logsysconfig
HOSTNAME=$lshost
SITENAME=$site
SITE=$site
SITENUM=$snum
SITELOC=$siteloc
DOMAINNAME=$dnsDom
OUTPUT1=https://elastic-node-${out1}.$2:9200
OUTPUT2=https://elastic-node-${out2}.$2:9200
OUTPUT3=https://elastic-node-${out3}.$2:9200
EOF

  chmod 660 $logsysconfig

}

#
#  This function is used to check if the logstash users/roles already exist in elastic.
#  Since the users/roles are generated during the initial logstash install for the cluster
#  if they already exist then the assumption is made that this is not the initial logstash
#  instance for the cluster and a logstash.keystore already exists and should be on the
#  repo server.
#
function checkUsersAndKeystore() {

  if [ "$(userExistsinKibana "logstash_internal")" == "true" ] &&
    [ "$(userExistsinKibana "logstash_admin_user")" == "true" ] &&
    [ "$(roleExistsinKibana "logstash_writer")" == "true" ]; then
    echo "Logstash users/roles already exist in Kibana, verifying that logstash.keystore is on repo server"

    # First check to make sure logstash.keystore is available
    status=$(curl --head --silent https://"$fileloc"/keystores/logstash.keystore | head -n 1)
    if ! echo "$status" | grep -q OK; then
      echo
      echo "Logstash Keystore not found on $fileloc, cannot continue."
      echo
      echo "You MUST Copy:"
      echo
      echo "     /etc/logstash/logstash.keystore "
      echo
      echo "  from a working logstash installation to:"
      echo
      echo "     $fileloc/keystores/logstash.keystore"
      echo
      echo "and try again..."
      echo
      exit
    fi
  else
    newKeystore="true"
  fi

}

# Function: createaliases
# Parameters: Index with site number ${bsindex}
# Desc: Create alias for bootstrapped indexes
function createaliases() {
  alias=$(curl -w 'return_code=%{http_code}\n' --silent -k -XGET -u "${user}":"${passwd}" "https://${ES_HOST}.${clusterSite}:${ES_PORT}/_cat/aliases/$1")
  retcode=$(echo "$alias" | awk -F 'return_code=' '{print $2}' | sed '/^$/d')
  if [ "$retcode" == "200" ]; then
    alias=$(echo "$alias" | awk -F 'return_code' '{print $1}' | sed '/^$/d')

    if [ -z "$alias" ]; then
      echo "No Alias found for index: $1, creating..."

      curl -k -u "${user}":"${passwd}" -XPUT "https://${ES_HOST}.${clusterSite}:${ES_PORT}/%3C${1}-%7Bnow%2Fm%7Byyy-MM-dd%7D%7D-000001%3E" -H 'Content-Type: application/json' -d'
{
    "aliases" : {
        "'"$1"'" : {
             "is_write_index" : true
        }
     }
}
'
    else
      echo
      echo "Alias for $1 already exists..."
    fi
  else
    echo
    echo "*** ERROR *** "
    echo "Bad return code from curl: $retcode, did you enter your password incorrectly?"
    return
  fi
}

# Function: bootstrapindexes
# Parameters: None
# Desc: Bootstraps site specific indexes as defined by indexes array
function bootstrapindexes() {
  # Lets figure out the version to bootstrap based on version of installed logstash
  bsver=$(/usr/share/logstash/bin/logstash --version | /bin/grep ^logstash | /bin/cut -f2 -d' ')

  if [ -z "$bsver" ]; then
    echo
    echo "*** ERROR *** "
    echo "Unable to determine logstash version, unable to bootstrap indexes."
    echo "Contact an Elastic SME for guidance..."
    echo
    exit 1
  fi

  # Add version environment variable
  sed -i -n -e '/^VER=/!p' -e '$ aVER='"${bsver}"'' $logsysconfig

  #
  # This is an array of all indexes to be bootstrapped
  #
  indexes=(metricbeat-"${bsver}" dcgs-syslog-iaas-ent dcgs-audits_syslog-iaas-ent)

  #
  # loop through array and create initial indexes for all
  #
  for index in "${indexes[@]}"; do
    echo "updating index template : $index"

    addons=""
    bsindex=${index}-${snum}

    if [[ ${index} == *-iaas-ent ]]; then
      indexname=${index#"dcgs-"}
      indexname=${indexname%-iaas-ent}
      componentname=${indexname}

      if [ "${indexname}" == "syslog" ]; then
        addons=", \"estc_dcgs_app_defaults\""
      fi

      if [ "${indexname}" == "audits_syslog" ]; then
        addons=", \"estc_loginsight-agent-mappings\""
      fi

      indexname=${indexname}-${snum}
    else
      indexname=${bsindex}
      componentname=${index}

    fi

    curl -k -u "${user}":"${passwd}" -XPUT "https://${ES_HOST}.${clusterSite}:${ES_PORT}/_index_template/esti_${indexname}?pretty" -H 'Content-Type: application/json' -d'
  {
    "template" : {
      "settings" : {
        "index" : {
          "lifecycle" : {
            "rollover_alias" : "'"$bsindex"'"
          }
        }
      }
   },
     "index_patterns" : [
       "'"$bsindex"'*"
     ],
     "composed_of" : [ "estc_dcgs_defaults","estc_'"$componentname"'-mappings"'"$addons"' ],
     "priority" : 400,
     "version" : 0
}
'

    echo "checking alias for $bsindex..."
    createaliases "${bsindex}"

  done
}

# Function: createoverride
# Parameters: None
# Desc: Create override file for Logstash service and sets StanardOutput to null
function createoverride() {
  mkdir -p /etc/systemd/system/logstash.service.d
  cat <<EOF >/etc/systemd/system/logstash.service.d/override.conf
[Service]
StandardOutput=null
EOF

  systemctl daemon-reload
}

# Function: updatelog4j
# Parameters: None
# Desc: update log4j with new settings, change permissions and remove all old log files
function updatelog4j() {
  mv /var/log/logstash /var/log/logstash.backup
  mkdir /var/log/logstash
  chown logstash:root /var/log/logstash
  chmod 755 /var/log/logstash

  curl --silent https://"$fileloc"/install/artifacts/log4j2.properties.logstash -o $log4j
  chmod 644 $log4j
  chown root:logstash $log4j
}

# Function: metricsin
# Parameters: None
# Desc: Ensure metrics_in directory for esp_metricbeat pipeline exists
function metricsin() {
  if [ ! -d /ELK-local/metrics_in ]; then
    mkdir -p /ELK-local/metrics_in
  fi
  chown logstash /ELK-local/metrics_in
}

####################
# Main begins here #
####################

echo
echo "*** NOTICE *** "
echo "This script will install a Logstash Instance..."
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
  echo "   Enter 1 for 6 Nodes"
  echo "   Enter 2 for 10 Nodes"
  echo "   Enter 3 for 15 Nodes"
  read -p "Enter a value (1-3): " -r numNodes </dev/tty
  echo
done

#
# Query site of Elastic Cluster for Lostash destination
#
echo
read -p "Enter site of Elastic cluster this Logstash will send to(ex: ech, cte). default [ech] :" -r clusterSite </dev/tty
clusterSite=${clusterSite:-ech}
echo

# Validate logstash is not already installed, if so this should be an upgrade

if systemctl list-units --type=service -all | grep -Fq logstash; then
  echo "Logstash service is already installed, script aborted."
  echo "Check instructions for upgrade steps..."
  exit
fi

echo "This script will preform a new install of logstash..."
checkUsersAndKeystore
checkCerts
yum -y install logstash
getCerts
SetupKeystore
updateJvmOptions

#
# get site location
#
getsitesyml
#
# Update site location for elastic documents
#
addSysconfig "$numNodes" "$clusterSite"
#
# Create override.conf for logstash service
#
createoverride
#
# Update log4j settings
#
updatelog4j
#
# Create metrics-in directory and make sure
# it's owned by logstash
#
metricsin
#
# Copy lastest jdbc drivers
#
latestjdbc
#
# bootstrap indexes and create aliases
#
bootstrapindexes
#
# Run puppet to update logstash.yml file, dictionaries and patterns
#
puppet agent -t

# make sure service is enabled
systemctl enable logstash

echo "Logstash installation complete..."
#################################################################################
#
#			    Unclassified
#
#################################################################################
