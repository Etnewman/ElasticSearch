#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Convenience script to upgrade kibana
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: update_kibana_settings.sh
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
user=$SUDO_USER
kibanaYML="/etc/kibana/kibana.yml"
site=$(hostname -d | cut -f1 -d".")
clustername=${site^^}_Cluster
ver=$(/usr/share/kibana/bin/kibana-setup --version)
site_num=$(hostname | cut -c 2-3)

# Check to see if this is WCH Cluster
if [ "${site_num,,}" == "0a" ]; then
  kibana="kibana-wch"
else
  kibana="kibana"
fi

function configbanner() {
  # Initialize variables
  #
  # Get classification from first letter of hostname then change it to uppercase
  class="$(hostname | cut -c 1)"
  classification="${class^^}"

  #
  # Install banner based on classification of system
  echo -n "Installing security banner - "
  case $classification in
  U)
    echo "Unclassified detected"
    textContent="UNCLASSIFIED"
    textColor="#000000"
    backgroundColor="#008b02"
    ;;
  S)
    echo "SECRET detected"
    textContent="SECRET"
    textColor="#000000"
    backgroundColor="#f20000"
    ;;
  T)
    echo "TS/SCI detected"
    textContent="TS/SCI"
    textColor="#000000"
    backgroundColor="#ffff00"
    ;;
  *)
    echo "No classification found"
    echo "Hostname doesn't conform to DCGS conventions"
    textContent="N/A"
    textColor="#ffffff"
    backgroundColor="#000000"
    ;;
  esac

  #
  # Get list of spaces
  spaces=$(curl -k -s -u "${user}":"${passwd}" -k "https://${kibana}/api/spaces/space" | tr "," "\n" | grep id | cut -f2 -d: | tr -d '\042')
  #
  # Loop through spaces to set banner
  for space in ${spaces}; do
    #
    # Rest api to set security banner for each space
    curl -k -s -u "${user}":"${passwd}" -XPUT "https://${kibana}/s/${space}/api/saved_objects/config/${ver}" -H "kbn-xsrf: reporting" -H "Content-Type: application/json" -d' {     "attributes": {         "banners:placement": "top",         "banners:textColor":"'$textColor'",         "banners:backgroundColor":"'$backgroundColor'",         "banners:textContent": "'$textContent'    '"${clustername}"'"     } }' >/dev/null

    echo "Installing dark mode on space: ${space}"
    curl -k -s -u "${user}":"${passwd}" -XPUT "https://${kibana}/s/${space}/api/saved_objects/config/${ver}" -H "kbn-xsrf: reporting" -H "Content-Type: application/json" -d' {     "attributes": {         "theme:darkMode": "true" } }' >/dev/null

  done
}

## Main ##

read -sp "User <$user> will be used to update kibana settings $user: " -r passwd </dev/tty
echo

# Ensure password provided is valid
pwcheck=$(curl -k --silent -u "${user}":"${passwd}" "https://${kibana}/api/spaces/space" --write-out '%{http_code}')

retval=${pwcheck: -3}
if [[ $retval != 200 ]]; then
  echo
  echo "Unable to communicate with Kibana. Did you enter your password correctly?"
  echo "Script aborted, please try again."
  echo
  exit
fi

#
# Make sure this runs only on kibana
#
if [ -s "$kibanaYML" ]; then
  configbanner
else
  echo "Script NOT executed, this script needs to be run on a Kibana node."
  echo "Please login to a Kibana node and try again."
fi

echo "Kibana settings updated"
#################################################################################
#
#			    Unclassified
#
#################################################################################
