#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Used to insert Application filter section updates into an
#          active Pipeline in Kibana
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: insertIntoPipeline.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Brian Gaffney, 2022-08-15: Original Version
#   v1.01, CR-2021-OADCGS-035, Brian Gaffney, 2022-10-31: Make it callable from other scripts
#   v1.02, CR-2021-OADCGS-035, Brian Gaffney, 2023-01-31: Add option to update a different pipeline
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
# Initialize variables
#

if [[ $# -lt 2 ]]; then
  echo "Usage: insertIntoPipeline.sh (-i | -u) Filename [--password Password]"
  echo "       If provided, Password is used to connect to Elastic"
  echo "       If the pipeline to be modified is not esp_filbeat, the name must be"
  echo "          exported as LOGSTASH_PIPELINE by the calling script."
  exit 1
fi

Function=$1
if [[ "$Function" != "-i" && $Function != "-u" ]]; then
  echo "Invalid function: '$Function', must be '-i' or '-u'."
  exit 1
fi

AppName=$2
if [ "$Function" == "-i" ] && [ ! -f "${AppName}.filebeat-filter" ]; then
  echo "Filebeat filter file to be inserted must exist - ${AppName}.filebeat-filter"
  exit 1
fi

# Set up for access
user=$SUDO_USER
if [ -z "$user" ] || [ "$user" == "root" ]; then
  echo "ERROR: Script needs to be run from 'sudo su' not 'sudo su -'.  And don't run su twice (SUDO_USER needs to contain your username)."
  exit 1
fi

# Allow calling script to pass password, rather than requiring entry twice.
if [[ $# -ge 4 && "$3" == "--password" ]]; then
  passwd=$4
else
  read -sp "User <$user> will be used to get and load pipeline in elastic, please enter the password for $user: " -r passwd </dev/tty
  echo
fi

# Get name of pipeline to modify from calling script, or use default.
if [ -z "${LOGSTASH_PIPELINE}" ]; then
  LOGSTASH_PIPELINE=esp_filebeat
fi

echo
# Get active Filebeat pipeline
echo "Pulling from Kibana to /tmp/${LOGSTASH_PIPELINE}.get"
curl -k -XGET -u "$user":"$passwd" "https://kibana/api/logstash/pipeline/${LOGSTASH_PIPELINE}" >"/tmp/${LOGSTASH_PIPELINE}.get"
if ! grep -q "##### Add New Filter Sections Here #####" "/tmp/${LOGSTASH_PIPELINE}.get"; then
  echo "*** ERROR *** "
  echo "Getting ${LOGSTASH_PIPELINE} from Kibana failed."
  exit 1
fi

# Remove unneeded fields
echo "Converting to PUT format in /tmp/${LOGSTASH_PIPELINE} (removing id and username)"
sed 's/"id":".*","description"/"description"/' "/tmp/${LOGSTASH_PIPELINE}.get" | sed 's/"username":".*","pipeline"/"pipeline"/' >"/tmp/${LOGSTASH_PIPELINE}"

echo "Convert to multiline format in /tmp/${LOGSTASH_PIPELINE}.pipeline"
sed 's/\\n/\n/g' "/tmp/${LOGSTASH_PIPELINE}" | sed '0,/{/ s/"id":.*","d/"d/; 0,/{/ s/"username":.*,"p/"p/' >"/tmp/${LOGSTASH_PIPELINE}.pipeline"

# Create backup file for later comparison
cp "/tmp/${LOGSTASH_PIPELINE}.pipeline" "/tmp/${LOGSTASH_PIPELINE}.bak"

echo
if [[ $Function == "-i" ]]; then
  # Add new filter content at 'tag' location, replace if already there
  if grep -q "    ##### Start ${AppName} Filter #####" "/tmp/${LOGSTASH_PIPELINE}.pipeline"; then
    echo "Replacing existing Filter section (backed up to /tmp/${LOGSTASH_PIPELINE}.pipeline.bak1)"
    sed -i.bak1 -n -e '1h;1!H;${;g;' \
      -e "s/\(    ##### Start ${AppName} Filter #####\).*\(    ##### End ${AppName} Filter #####\)/\1/" \
      -e "p}" "/tmp/${LOGSTASH_PIPELINE}.pipeline"
    sed -i -e "/    ##### Start ${AppName} Filter #####/ {" \
      -e "r ${AppName}.filebeat-filter" \
      -e "a\    ##### End ${AppName} Filter #####" \
      -e "}" "/tmp/${LOGSTASH_PIPELINE}.pipeline"
  else
    echo "Inserting Filter section (backed up to /tmp/${LOGSTASH_PIPELINE}.pipeline.bak1)"
    sed -i.bak1 -e "/##### Add New Filter Sections Here #####/ {" \
      -e "i\    ##### Start ${AppName} Filter #####" \
      -e "r ${AppName}.filebeat-filter" \
      -e "a\    ##### End ${AppName} Filter #####" \
      -e"N}" \
      "/tmp/${LOGSTASH_PIPELINE}.pipeline"
  fi
else # Function == -u
  if grep -q "    ##### Start ${AppName} Filter #####" "/tmp/${LOGSTASH_PIPELINE}.pipeline"; then
    echo "Removing existing Filter section (backed up to /tmp/${LOGSTASH_PIPELINE}.pipeline.bak1)"
    sed -i.bak1 -n -e '1h;1!H;${;g;' \
      -e "s/    ##### Start ${AppName} Filter #####.*    ##### End ${AppName} Filter #####\n//" \
      -e "p}" "/tmp/${LOGSTASH_PIPELINE}.pipeline"
  fi
fi

# Only push to Kibana if the file has changed
if [[ $(diff "/tmp/${LOGSTASH_PIPELINE}.pipeline" "/tmp/${LOGSTASH_PIPELINE}.bak") ]]; then
  echo "Changes made to pipeline ..."

  # Convert back to single-line pipeline
  echo "Converting to single-line format in /tmp/${LOGSTASH_PIPELINE}"
  sed -z 's/\n/\\n/g;;$ s/\\n$/\n/' "/tmp/${LOGSTASH_PIPELINE}.pipeline" >"/tmp/${LOGSTASH_PIPELINE}"

  # Output updated pipeline
  echo "Pushing new /tmp/${LOGSTASH_PIPELINE} to Kibana"
  if ! curl -k -XPUT -u "$user":"$passwd" "https://kibana/api/logstash/pipeline/${LOGSTASH_PIPELINE}" -H 'kbn-xsrf:true' -H 'Content-Type: application/json' -d@"/tmp/${LOGSTASH_PIPELINE}"; then
    echo
    echo "*** ERROR *** "
    echo "Pushing ${LOGSTASH_PIPELINE} to Kibana failed."
    exit 1
  fi

else
  echo "No changes from existing pipeline, not pushing to Kibana"
fi

echo
