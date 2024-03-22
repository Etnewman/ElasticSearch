#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Activates the ACAS portion of the Elastic Data Collector.
#
# Tracking #: CR-2020-OADCGS-086
#
# File name: activate_hbssdlp.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2020-OADCGS-086, Steve Truxal, 2020-06-29: Original Version
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
# Frequency: When adding a pipeline to Kibana is necessary
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
# Initialize Variables
#

FILE=/etc/logstash/scripts/data/hbssdlp.dat
scriptDir="/etc/logstash/scripts"

if [ -f "$FILE" ]; then
  echo "HBSS DLP has already been configured for HBSS DLP Rest API collection, continuing will overwrite the current hbssdlp.dat file deleting the existing access keys; Are you sure you want to continue?"
  read -p "Overwrite File?(Y/N): " -r yn </dev/tty
  case $yn in
  [Yy]*)
    echo "hbssdlp.dat will be overwritten, continuing with activation."
    ;;
  *)
    echo "hbssdlp.dat was not overwritten. Exiting..."
    return 0
    ;;
  esac
fi

echo
echo "Please enter the data as it appears in the install instructions."
echo
read -p "Please enter the Hostname for the HBSS DLP server : " -r HOSTNAME </dev/tty
echo
read -p "Please enter the Port for the HBSS DLP Rest API call on host: $HOSTNAME : " -r PORT </dev/tty
echo
read -p "Please enter the User for the HBSS DLP Rest API call on host: $HOSTNAME : " -r USER </dev/tty
echo
read -p "Please enter the Password for the HBSS DLP Rest API call on host: $HOSTNAME : " -r PASS </dev/tty
echo

# Activate virtual environment so that Crypt.py can be used
# Disable shellcheck for source line because activate script is not part of the baseline
# shellcheck disable=SC1091
source /etc/logstash/scripts/venv/bin/activate

echo
echo "Writing to hbssdlp.dat..."

# Writing to ACAS.dat
cat <<EOF >$FILE
$HOSTNAME
$PORT
$USER
$(python $scriptDir/Crypt.py -e "$PASS")
EOF
deactivate

echo "Note: This pipeline will not be used until added to the logstash.yml file in puppet to pull HBSS DLP data."
echo
echo "DONE: Configuring HBSS DLP configuration"
