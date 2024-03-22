#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Upgrade Logstash Instance to latest version on repo server
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: upgrade_logstash.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, date it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Steve Truxal, 2021-08-22: Original Version
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
log4j="/etc/logstash/log4j2.properties"
logsysconfig="/etc/sysconfig/logstash"
sitename=$(grep "SITENAME" "$logsysconfig" | cut -d= -f2)
mssqljdbcver="7.2.2"
postgresqlver="42.3.1"
snum=$(hostname | cut -c 2-3)
ES_HOST="elastic-node-1"
ES_PORT="9200"
user=$SUDO_USER
clusterSites=()
scriptDir="/etc/logstash/scripts"
removeDAT="true"
notifyCheck="false"
file="bootstrap_site_specific.sh"

# Function: getsitesyml
# Parameters: None
# Desc: pull sites.yml file to /tmp to update siteloc
function getsitesyml() {
  curl -k --silent https://"$fileloc"/install/sites.yml >/tmp/sites.yml
  siteloc=$(sed 's/ *//g' /tmp/sites.yml | grep ^"$snum" | cut -d: -f2)
  rm /tmp/sites.yml
}

# Function: updateJVMOption
# Parameters: None
# Desc: Update size of JVM defined based on machine's memory
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

  # Check for jvm.options file
  if [ -f "/etc/logstash/jvm.options" ]; then
    echo "jvm.options file is available."
  else
    echo "No jvm.options file available, using the previous version."
    cp /etc/logstash/jvm.options.prev /etc/logstash/jvm.options
  fi

  sed -i "s/-Xms1g/-Xms${mem}g/g" /etc/logstash/jvm.options
  sed -i "s/-Xmx1g/-Xmx${mem}g/g" /etc/logstash/jvm.options
}

# Function: upgradelogstash
# Parameters: None
# Desc: upgrade logstash to lastest from yum repo
function upgradelogstash() {
  echo
  yum clean all
  systemctl stop logstash
  #Check if Logstash is upgradable
  #Upgrading variables line
  package="logstash"
  SUB="No matching Packages"

  #Checks for available updates for logstash on the system
  eVerCheck=$(yum list available $package 2>&1)
  haslatest=$(echo "$eVerCheck" | grep -i "$SUB")

  if [ "$haslatest" ]; then
    echo "Logstash is running the latest available version, no software upgrade will be performed."
  else
    echo "New logstash version available, executing upgrade script."
    # Remove new rpm file
    if [ -f "/etc/logstash/jvm.options.rpmnew" ]; then
      rm -f /etc/logstash/jvm.options.rpmnew
    fi

    # Move existing jvm.option file to .prev
    if [ -f "/etc/logstash/jvm.options" ]; then
      mv -f /etc/logstash/jvm.options /etc/logstash/jvm.options.prev
    fi

    yum -y upgrade logstash
    updateJvmOptions
  fi
}

# Function: updatessysconfig
# Parameters: None
# Desc: Updates /etc/sysconfig/logstash
function updatesysconfig() {
  # If the site doesn't exist set it to UNKNOWN
  if [ -z "$siteloc" ]; then
    siteloc="UNKNOWN"
  fi
  sed -i -n -e '/^SITE=/!p' -e '/SITENAME/a SITE='"${sitename}"'' $logsysconfig
  sed -i -n -e '/^SITELOC=/!p' -e '/SITENUM/a SITELOC='"${siteloc}"'' $logsysconfig
  realmDom=$(realm list -n)
  sed -i -n -e '/^DOMAINNAME=/!p' -e '/SITELOC/a DOMAINNAME='"${realmDom}"'' $logsysconfig
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

  curl -k --silent https://"$fileloc"/install/artifacts/log4j2.properties.logstash -o $log4j
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

# Function: latestjdbc
# Parameters: None
# Desc: Pull over latest jdbc drivers
function latestjdbc() {
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

# Checks if the user exists in Kibana and returns 'true' if it doesn't
## $1 = cluster site
function checkUsers() {
  if [ "$(userExistsinKibana "ls_internal" "$1")" == "true" ] &&
    [ "$(userExistsinKibana "ls_admin" "$1")" == "true" ]; then
    echo "$1 Logstash users/roles already exist in Kibana, verifying that ls_users.dat is on repo server"
    newUsersDat="false"
  else
    newUsersDat="true"
  fi
}

# Curl command to check user existing in kibana
## $1 = LS username, $2 = cluster site
function userExistsinKibana() {
  userExists=$(curl -ks -u "${user}":"${passwd}" "https://${ES_HOST}.${2}:${ES_PORT}/_security/user/$1")
  if [ "$userExists" == "{}" ]; then echo "false"; else echo "true"; fi
}

# Checks if the .DAT file is present on the repo server, and exits if it doesn't
function checkDatFile() {
  status=$(curl -k --head --silent https://"$fileloc"/keystores/ls_users.dat | head -n 1)
  if ! echo "$status" | grep -q OK; then
    echo
    echo "LS Users not found on $fileloc/keystores/ls_users.dat, cannot continue."
    echo
    echo "You MUST Copy the following file:"
    echo
    echo "     /tmp/ls_users.dat "
    echo
    echo "from the first Logstash upgraded to:"
    echo
    echo "     yum/sync/elastic/keystores/ls_users.dat "
    echo
    echo "and try again..."
    echo
    echo "Note: Ensure Satellite administrator pre-publishes"
    echo "Elastic files repository after updating."
    echo
    exit
  fi
}

# Notify installer to copy keystore to repo server
function notifyCopy() {
  echo
  echo "     ******************* IMPORTANT NOTICE ********************************"
  echo "     *                                                                   *"
  echo "     * Logstash Keystore created during installation.                   *"
  echo "     *                                                                   *"
  echo "     * You MUST Copy:                                                    *"
  echo "     *                                                                   *"
  echo "     *    /tmp/ls_users.dat                                              *"
  echo "     *                                                                   *"
  echo "     * from this machine to the Master repository at:                    *"
  echo "     *                                                                   *"
  echo "     *    yum/sync/elastic/keystores/ls_users.dat                        *"
  echo "     *                                                                   *"
  echo "     * To allow installation of other Logstash instances.                *"
  echo "     *                                                                   *"
  echo "     * Note: Ensure Satellite administrator re-publishes                *"
  echo "     *       Elastic files repository after updating.                    *"
  echo "     *                                                                   *"
  echo "     ******************* IMPORTANT NOTICE ********************************"
  echo
}

# Reads the ls_users.dat file and decrypts the passwords for future use
function decryptPasswords() {
  IFS=':' read -r ls_internal LS_INTERNAL_PW_E <<<"$(head -n 1 "/tmp/ls_users.dat")"
  IFS=':' read -r ls_admin LS_ADMIN_PW_E <<<"$(sed -n '2p' "/tmp/ls_users.dat")"
  LS_INTERNAL_PW=$(/etc/logstash/scripts/venv/bin/python $scriptDir/Crypt.py -d "$LS_INTERNAL_PW_E")
  LS_ADMIN_PW=$(/etc/logstash/scripts/venv/bin/python $scriptDir/Crypt.py -d "$LS_ADMIN_PW_E")
}

# Bootstraps the ls_internal and ls_admin users, also creates the .DAT file if it doesn't already exist
## $1 = cluster site
function bootstrapLogstashUsers() {
  echo "Bootstrapping Logstash users..."
  removeDAT="false"
  notifyCheck="true"

  ###### Bootstrap users
  #### Check if ls_users.dat already exists so we don't overwrite with new passwords
  if [ -e "/tmp/ls_users.dat" ]; then
    echo "ls_users.dat already exists in tmp, forwarding to elastic"
    decryptPasswords
  else
    # create ls_internal user with random password
    LS_INTERNAL_PW=$(tr -cd '[:alnum:]' </dev/urandom | fold -w15 | head -n1)
    # create ls_admin user with random password
    LS_ADMIN_PW=$(tr -cd '[:alnum:]' </dev/urandom | fold -w15 | head -n1)

    #### Encrypt and Write to .DAT file
    cat <<EOF >/tmp/ls_users.dat
LS_INTERNAL_PW:$(/etc/logstash/scripts/venv/bin/python $scriptDir/Crypt.py -e "$LS_INTERNAL_PW")
LS_ADMIN_PW:$(/etc/logstash/scripts/venv/bin/python $scriptDir/Crypt.py -e "$LS_ADMIN_PW")
EOF
  fi

  curl -k -u "${user}":"${passwd}" -XPUT "https://${ES_HOST}.${1}:${ES_PORT}/_security/user/ls_internal" -H 'Content-Type: application/json' -d'
  {
    "password" : '\""$LS_INTERNAL_PW"\"',
    "roles" : ["logstash_writer"],
    "full_name" : "Internal Logstash User"
  }
  '

  curl -k -u "${user}":"${passwd}" -XPUT "https://${ES_HOST}.${1}:${ES_PORT}/_security/user/ls_admin" -H 'Content-Type: application/json' -d'
  {
    "password" : '\""$LS_ADMIN_PW"\"',
    "roles" : ["logstash_writer","logstash_admin"],
    "full_name" : "Logstash Admin User"
  }
  '
}

function updateKeystore() {
  ## Set the environment variables for keystore operations
  set -o allexport
  # shellcheck source=/dev/null
  source /etc/sysconfig/logstash

  #### Decrypt the passwords to update keystore
  decryptPasswords

  #### Remove pw_name, then echo pw and add pw_name
  # Add Logstash output user "ls_internal" password to keystore
  echo "Adding LS_INTERNAL_PW to keystore..."
  /usr/share/logstash/bin/logstash-keystore remove "$ls_internal" --stdin --path.settings /etc/logstash >>/dev/null
  echo "$LS_INTERNAL_PW" | /usr/share/logstash/bin/logstash-keystore add "$ls_internal" --stdin --path.settings /etc/logstash >>/dev/null

  echo "Adding LS_ADMIN_PW to keystore..."
  # Add Logstash output user "ls_admin" password to keystore
  /usr/share/logstash/bin/logstash-keystore remove "$ls_admin" --stdin --path.settings /etc/logstash >>/dev/null
  echo "$LS_ADMIN_PW" | /usr/share/logstash/bin/logstash-keystore add "$ls_admin" --stdin --path.settings /etc/logstash >>/dev/null
}

# $1 = cluster site
function handleLogstashUsers() {
  # Check if ls_internal and ls_admin exist
  checkUsers "$1"
  if [ "$newUsersDat" == "true" ]; then
    echo "$1 Logstash users/roles do not exist in Kibana, creating and adding to logstash.keystore"
    # Create Users in Elastic and .DAT file
    bootstrapLogstashUsers "$1"
  else
    if [ ! -e "/tmp/ls_users.dat" ]; then
      # Check if .DAT file on Repo
      checkDatFile
      # CURL over .DAT file into /tmp
      curl -k --silent https://"$fileloc"/keystores/ls_users.dat >/tmp/ls_users.dat
    fi
  fi
}

#
# Main
#

#
# Set username and password
#
echo "."
read -sp "User <$user> will be used to bootstrap site specific indexes in elastic, please enter the password for $user: " -r passwd </dev/tty
echo

#
# Query site of Elastic Cluster for Logstash destination
#
echo
read -p "Enter site of primary Elastic cluster this Logstash will send to(ex: ech, isec). default [ech]: " -r clusterSite </dev/tty
clusterSites+=("${clusterSite:-ech}")
echo

if [[ "${clusterSites[0]}" == "ech" ]]; then
  echo
  echo "Setting secondary cluster to wch..."
  clusterSites+=("wch")
  echo
fi

#
# Ensure password provided is valid
#
for clusterSite in "${clusterSites[@]}"; do
  if [ -n "$clusterSite" ]; then
    pwcheck=$(curl -k --silent -u "${user}":"${passwd}" "https://${ES_HOST}.${clusterSite}:${ES_PORT}/_cluster/health" --write-out '%{http_code}')
    retval=${pwcheck: -3}
    if [[ $retval != 200 ]]; then
      echo
      echo "Unable to communicate with $clusterSite Elasticsearch. Did you enter your password correctly?"
      echo "Script aborted, please try again."
      echo
      exit
    fi
  fi
done

#
# Retrieve bootstrap_site_specific.sh
#
curl -k --silent https://"$fileloc"/install/"$file" >/tmp/"$file"
if [ -e "/tmp/$file" ]; then
  checkLine=$(head -n 1 "/tmp/$file")
  if [[ $checkLine == *"404"* ]]; then
    echo "$file did not cURL properly. Check the Sat Repo."
    exit
  fi
else
  echo "Couldn't reach $file. (Did you enter your credentials correctly?)"
  exit
fi
chmod +x /tmp/bootstrap_site_specific.sh

#
# upgrade logstash package
#
upgradelogstash

#
# Handler function for ls_internal and ls_admin
# Bootstrap indexes and create aliases
#
for clusterSite in "${clusterSites[@]}"; do
  if [ -n "$clusterSite" ]; then
    handleLogstashUsers "$clusterSite"
    bash /tmp/bootstrap_site_specific.sh "$clusterSite"
  fi
done

# Update the keystore from the contents of the .DAT file
updateKeystore

# Check if we should notify the installer to copy ls_users.dat into Sat Repo
if [ $notifyCheck == "true" ]; then
  notifyCopy
fi

# Remove .DAT if it already exists on repo
if [ $removeDAT == "true" ]; then
  rm /tmp/ls_users.dat
fi

rm /tmp/bootstrap_site_specific.sh

#
# get site location
#
getsitesyml
#
# Update site location for elastic documents
#
updatesysconfig
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

systemctl start logstash
sleep 10
systemctl status logstash

#
# Delete backup logstash log directory
#
rm -rf /var/log/logstash.backup

echo
echo
echo "Initial metricbeat indexes bootstrapped, log4j fixes, updated jdbc connector and /etc/sysconfig/logstash modified."
echo
echo "Logstash Upgrade Complete."
echo
echo
#################################################################################
#
#			    Unclassified
#
#################################################################################
