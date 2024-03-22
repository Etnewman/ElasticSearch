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
# File name: activate_acas.sh
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

user=$SUDO_USER
FILE=/etc/logstash/scripts/data/acas.dat
siteNum="$(hostname | cut -c 2-3)"
hostname="$(hostname | cut -c 1-7)ac01"
scriptDir="/etc/logstash/scripts"
index="dcgs-acas-iaas-ent"

read -sp "User <$user> will be used to activate acas, please enter password for $user: " -r passwd </dev/tty
echo

echo "This script will configure the data collector to collect data from $hostname."
while [[ ! $REPLY =~ ^[Yy]$ ]]; do
  read -p "Is this the correct hostname for the ACAS server<$hostname>? <y/n> " -n 1 -r </dev/tty
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter correct ACAS hostname:" -r hostname </dev/tty
  fi
done

echo "Continuing configuration for ACAS host: $hostname"

if [ -f "$FILE" ]; then
  echo "ACAS data collection has already been configured for this Elastic Data Collector, continuing will overwrite the current acas.dat file deleting the existing access keys; Are you sure you want to continue?"
  read -p "Overwrite File?(Y/N): " -r yn </dev/tty
  case $yn in
  [Yy]*)
    echo "acas.dat will be overwritten, continuing with activation."
    ;;
  *)
    echo "acas.dat was not overwritten. Exiting..."
    return 0
    ;;
  esac
fi

echo
echo "<$user>, Please enter just the key as it appears in the install instructions."
echo
read -p "<$user>, Please enter the ACCESS KEY for the SERVICE ACCOUNT on host: $hostname : " -r SCAK </dev/tty
echo
read -p "<$user>, Please enter the SECRET KEY for the SERVICE ACCOUNT on host: $hostname : " -r SCPK </dev/tty
echo
echo "<$user>, the hostname used for the ACAS configuration will be <$hostname>"

# Activate virtual environment so that Crypt.py and ACAS.py can be used
# Disable shellcheck for source line because activate script is not part of the baseline
# shellcheck disable=SC1091
source /etc/logstash/scripts/venv/bin/activate

echo
echo "Writing to acas.dat..."

# Writing to ACAS.dat
cat <<EOF >$FILE
$(python $scriptDir/Crypt.py -e "$SCAK")
$(python $scriptDir/Crypt.py -e "$SCPK")
$hostname
EOF

# Run the ACAS test connection function to test API Keys
retval=$(python /etc/logstash/scripts/ACAS.py -t)
echo
echo "$retval"
deactivate

if [[ "$retval" == *"ERROR"* ]]; then
  echo "Please confirm API Keys."
  return
fi

# Start bootstrapping

echo
echo -n "checking alias for $index..."

alias=$(curl -w 'return_code=%{http_code}\n' --silent -k -XGET -u "${user}":"${passwd}" "https://elastic-node-1:9200/_cat/aliases/$index?h=alias,is_write_index")

# shellcheck disable=SC2206
alias=($alias)

haswrite="false"
for ((i = 0; i < ${#alias[@]}; i++)); do

  if [[ ${alias[i]} == "$index" ]]; then
    if [[ ${alias[++i]} == "true" ]]; then
      haswrite="true"
    fi
  elif [[ ${alias[i]} =~ return.* ]]; then
    retcode=$(echo "${alias[i]}" | awk -F 'return_code=' '{print $2}' | sed '/^$/d')
  fi
done

if [ "$retcode" == "200" ]; then
  if [ ${haswrite} == "false" ]; then
    echo
    echo "No Alias found for index: $index, creating..."
    curl -k -u "${user}":"${passwd}" -XPUT "https://elastic-node-1:9200/%3C${index}-%7Bnow%2Fm%7Byyy-MM-dd%7D%7D-000001%3E" -H 'Content-Type: application/json' -d'
{
    "aliases" : {
        "'"$index"'" : {
             "is_write_index" : true
        }
     }
}
'

  else
    echo
    echo "Alias Found."
  fi
else
  echo
  echo "*** ERROR *** "
  echo "Bad return code from curl: $retcode, did you enter your password incorrectly?"
fi

# Creating the ACAS delete role to delete old data

rolename="acas-delete"
echo
echo "Creating role: $rolename"
curl -XPUT -s -u "$user":"$passwd" https://elastic-node-1:9200/_security/role/${rolename} -H "Content-Type: application/json" -d'
{
	"cluster" : [ ],
	"indices" : [
		{
			"names" : [
				"dcgs-acas-*"
			],
			"privileges" : [
				"delete_index"
			],
			"field_security" : {
				"grant" : [
					"*"
				],
				"except" : [ ]
			},
			"allow_restricted_indices" : false
		}
	],
	"applications" : [ ],
	"run_as" : [ ],
	"metadata" : { },
	"transient_metadata" : {
		"enabled" : true
	}
}
'

# Map ACAS delete role to site querier user
current_roles=$(curl --silent -XGET -u "$user":"$passwd" https://elastic-node-1:9200/_security/user/querier-"$siteNum" -H "kbn-xsrf: reporting" | sed 's/^.*\(":\[\".*]\).*$/\1/' | sed 's/^..//')
if [[ "$current_roles" != *"$rolename"* ]]; then
  new_roles=${current_roles:0:-1},\"${rolename}\"]
  echo
  echo "Assigning $rolename role to querier-$siteNum"
  curl -XPUT -s -u "$user":"$passwd" https://elastic-node-1:9200/_security/user/querier-"$siteNum" -H "Content-Type: application/json" -d'
  {
  	"roles" : '"$new_roles"'
  }
  '
fi

# Copy ACAS.cron into cron.daily so that ACAS.py can be run daily
echo
echo "Copying ${scriptDir}/crons/acas.cron into /etc/cron.daily/acas.cron"
cp $scriptDir/crons/acas.cron /etc/cron.daily/acas.cron
chmod +x /etc/cron.daily/acas.cron

echo
echo "DONE: Activating ACAS"
