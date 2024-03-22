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
# File name: insertSectionIntoPipeline.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Brian Gaffney, 2023-03-20: Original Version
#
# Site/System: Repo Server (ro01)
#
# Deficiency: N/A
#
# Use: This script is used to insert a new section (e.g. from an ART) into
#      a filebeat pipeline.  (Converting formatting, etc.)
#
# Users: Elastic ART integrators
#
# DAC Setting: 755 apache apache
# Required SELinux Security Context : httpd_sys_content_t
#
# Frequency: Utility Script, used as needed.
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

if [[ $# -lt 3 ]]; then
  echo "Usage: insertIntoPipeline.sh (-i | -u) AppName Pipeline.Filename [-c]"
  echo "       -i    Insert Appname.filebeat-filter into Pipeline.Filename"
  echo "       -u    Un-insert Appname section from Pipeline.Filename"
  echo "       -c    Convert Appname.filebeat-filter from Logstash .conf format first"
  exit 1
fi

Function=$1
if [[ "$Function" != "-i" && $Function != "-u" ]]; then
  echo "Invalid function: '$Function', must be '-i' or '-u'."
  exit 1
fi

AppName=$2
if [ "$Function" == "-i" ] && [ ! -f "${AppName}.filebeat-filter" ]; then
  echo "Application filter file to be inserted must exist - ${AppName}.filebeat-filter"
  exit 1
fi

PipeName=$3
if [ ! -f "${PipeName}" ]; then
  echo "Pipeline file to be inserted must exist - ${PipeName}"
  exit 1
fi

echo
# Check pipeline content
if ! grep -q "##### Add New Filter Sections Here #####" "${PipeName}"; then
  echo "*** ERROR *** "
  echo "Pipeline ${PipeName} must contain a 'Add New Filter Sections Here' tag."
  exit 1
fi

if [ "$4" == "-c" ] || [ "$4" == "-C" ]; then
  echo "Convert ${AppName}.filebeat-filter to pipeline format"
  sed -i.bak 's/\\/\\\\/g;s/\"/\\\"/g;s/\t/\\t/g;s/\r/\\r/g;s/\\r$//' "${AppName}.filebeat-filter" >"${PipeName}.pipeline"
fi

cp "${PipeName}" "${PipeName}.pipeline"

# Create backup file for later comparison
cp "${PipeName}.pipeline" "${PipeName}.bak"

echo
if [[ $Function == "-i" ]]; then
  # Add new filter content at 'tag' location, replace if already there
  if grep -q "    ##### Start ${AppName} Filter #####" "${PipeName}.pipeline"; then
    echo "Replacing existing Filter section (backed up to ${PipeName}.pipeline.bak1)"
    sed -i.bak1 -n -e '1h;1!H;${;g;' \
      -e "s/\(    ##### Start ${AppName} Filter #####\).*\(    ##### End ${AppName} Filter #####\)/\1/" \
      -e "p}" "${PipeName}.pipeline"
    sed -i -e "/    ##### Start ${AppName} Filter #####/ {" \
      -e "r ${AppName}.filebeat-filter" \
      -e "a\    ##### End ${AppName} Filter #####" \
      -e "}" "${PipeName}.pipeline"
  else
    echo "Inserting Filter section (backed up to ${PipeName}.pipeline.bak1)"
    sed -i.bak1 -e "/##### Add New Filter Sections Here #####/ {" \
      -e "i\    ##### Start ${AppName} Filter #####" \
      -e "r ${AppName}.filebeat-filter" \
      -e "a\    ##### End ${AppName} Filter #####" \
      -e"N}" \
      "${PipeName}.pipeline"
  fi
else # Function == -u
  if grep -q "    ##### Start ${AppName} Filter #####" "${PipeName}.pipeline"; then
    echo "Removing existing Filter section (backed up to ${PipeName}.pipeline.bak1)"
    sed -i.bak1 -n -e '1h;1!H;${;g;' \
      -e "s/    ##### Start ${AppName} Filter #####.*    ##### End ${AppName} Filter #####\n//" \
      -e "p}" "${PipeName}.pipeline"
  fi
fi

# Restore original file, if necessary
if [ -f "${AppName}.filebeat-filter.bak" ]; then
  mv -f "${AppName}.filebeat-filter.bak" "${AppName}.filebeat-filter"
fi
# Check if the file has changed
if [[ $(diff "${PipeName}.pipeline" "${PipeName}.bak") ]]; then
  echo "Changes made to pipeline ..."

  cp "${PipeName}.pipeline" "${PipeName}"

else
  echo "No changes from existing pipeline"
fi

echo
