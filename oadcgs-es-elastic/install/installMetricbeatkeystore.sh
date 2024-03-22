#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Updates keystore with metricbeat user password
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: instMetrickeystore
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Steve Truxal, 2020-05-26: Original Version
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
# Frequency: During Elasticsearch Upgrade process
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
# function used to notify user to copy keystore to repo server
#
function notifyCopy() {
  # Notify installer to copy keystore to repo server
  echo
  echo "     ************************ IMPORTANT NOTICE ******************************"
  echo "     *                                                                      *"
  echo "     * Metricbeat Keystore created during installation.                     *"
  echo "     *                                                                      *"
  echo "     * You MUST Copy:                                                       *"
  echo "     *                                                                      *"
  echo "     *    /var/lib/metricbeat/metricbeat.keystore                           *"
  echo "     *                                                                      *"
  echo "     * from this machine to the Master repository at:                       *"
  echo "     *                                                                      *"
  printf "     *    yum/sync/elastic/keystores/%-23s                *\n" "$1"
  echo "     *    yum/sync/elastic/keystores/metricbeat-wch.keystore                *"
  echo "     *                                                                      *"
  echo "     * To allow installation of other Logstash instances.                   *"
  echo "     *                                                                      *"
  echo "     * Note: Ensure Satellite administrator re-publishes                    *"
  echo "     *       Elastic files repository after updating.                       *"
  echo "     *                                                                      *"
  echo "     ******************* IMPORTANT NOTICE ***********************************"
  echo
}

################################################################
#
# Function: metricbeatUser
#
# Desc: This function updates the metricbeat user password with a randomly
#       generated password and place this password in the metricbeat
#       keystore. If the user already exists in elasticsearch then
#       the metricbeat keystore is copied to the hosts from the repo server.
#
###############################################################
function metricbeatUser() {

  #
  # Initilize variables
  #

  fileloc="satrepo/pulp/content/oadcgs/Library/custom/Elastic_Client/Elastic_Files"
  user=$SUDO_USER
  ESNODE=elastic-node-1

  read -sp "User <$user> will be used to communicate with elastic, please enter the password for $user: " -r passwd </dev/tty
  echo

  # Keystore key name
  key=MB_PWD

  mbuser=metricbeat-user
  if [ -z "$1" ]; then
    ksname="metricbeat.keystore"
  else
    ksname="metricbeat-wch.keystore"
  fi

  # Generate random password for metricbeat user
  pass=$(tr -cd '[:alnum:]' </dev/urandom | fold -w15 | head -n1)

  ###### Metricbeat User users
  # First check to see if user already exists
  mbuserexists=$(curl -w 'return_code=%{http_code}\n' -s -k -u "$user":"$passwd" https://${ESNODE}:9200/_security/user/"$mbuser")
  retcode=$(echo "$mbuserexists" | awk -F 'return_code=' '{print $2}' | sed '/^$/d')
  if [ "$retcode" == "401" ] || [ "$retcode" == "403" ]; then
    echo
    echo "*** ERROR *** "
    echo "Bad return code from curl: $retcode, did you enter your password incorrectly?"
    exit 1
  fi

  if [ "$retcode" == "404" ]; then
    echo "Creating Metricbeat User and keystore..."
    result=$(curl -w 'return_code=%{http_code}\n' -k -u "$user":"$passwd" -XPOST -H 'Content-Type: application/json' "https://${ESNODE}:9200/_security/user/$mbuser" -d "{\"password\":\"$pass\",\"roles\": \"remote_monitoring_collector\", \"full_name\" : \"$mbuser User\"}")
    retcode=$(echo "$result" | awk -F 'return_code=' '{print $2}' | sed '/^$/d')
    if [ "$retcode" != "200" ]; then
      echo
      echo "*** ERROR *** "
      echo "Bad return code from curl: $retcode, Metricbeat User not created. Contact Elastic SME for Help."
      exit 1
    else
      ## Only attempt to create keystore if it doesn't already exist
      if [ ! -f /var/lib/metricbeat/metricbeat.keystore ]; then
        echo "Keystore doesn't exist so create"
        /bin/metricbeat keystore --path.config /etc/metricbeat create
      fi

      # Add key to metricbeat.keystore
      echo "$pass" | /bin/metricbeat keystore --path.config /etc/metricbeat add $key --stdin --force

      notifyCopy "$1"
    fi
  else
    echo
    echo "     ************************ IMPORTANT NOTICE ******************************"
    echo "     *                                                                      *"
    echo "     * Metricbeat-user exists, updating metricbeat.keystore...              *"
    echo "     *                                                                      *"
    echo "     *                                                                      *"
    echo "     ************************ IMPORTANT NOTICE ******************************"
    echo
    #
    # pull metricbeat.keystore
    #
    status=$(curl --head --silent https://"$fileloc"/keystores/"$ksname" | head -n 1)

    if ! echo "$status" | grep -q OK; then
      echo "     ********** ERROR ************** ERROR ************** ERROR ***************"
      echo "     *                                                                        *"
      printf "     * File not found on satellite server: %-23s            *\n" "$ksname"
      echo "     * Either metricbeat.keystore file originally created on elastic-node-1   *"
      echo "     * not copied to master repository (yum/sync/elastic/keystores).          *"
      echo "     * Or Elastic Files Repository not re-published after being updated.      *"
      echo "     * Ensure file was copied and re-published by Satellite administrator.    *"
      echo "     * When this is complete try running the script again.                    *"
      echo "     *                                                                        *"
      echo "     ********** ERROR ************** ERROR ************** ERROR ***************"

    else

      curl --silent https://"$fileloc"/keystores/"$ksname" -o /var/lib/metricbeat/metricbeat.keystore
      chmod 600 /var/lib/metricbeat/metricbeat.keystore
      echo "Metricbeat keystore installation complete..."
    fi
  fi

}

####################
# Main begins here #
####################

echo "Validating Metricbeat User and creating keystore..."
metricbeatUser "$1"
#################################################################################
#
#			    Unclassified
#
#################################################################################
