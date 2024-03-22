#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN/GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Used to create Kibana spaces for each site on the enclave,
#   and create roles and role mappings for site admins and users.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: create_spaces.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, date it was revised.
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Terry Northip, 2023-05-15: Original Version
#   v1.01, CR-2021-OADCGS-035, Brian Gaffney, 2023-06-01: Add Roles/Role_Mappings
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
# Frequency: During Elastic Install/Upgrade process
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

ES_HOST="elastic-node-1"
ES_PORT="9200"
# Get hostname, domain name, and repository server name
hostname=${HOSTNAME^^}
site=$(hostname | cut -c 1-3)
site_num=$(hostname | cut -c 2-3)
fileloc="satrepo/pulp/content/oadcgs/Library/custom/Elastic_Client/Elastic_Files"

# Check to see if this is WCH Cluster
if [ "${site_num,,}" == "0a" ]; then
  kibana="kibana-wch"
else
  kibana="kibana"
fi

# Get the user that executed the script
username=$SUDO_USER
if [ -z "$username" ] || [ "$username" == "root" ]; then
  echo "ERROR: Script needs to be run from 'sudo su' not 'sudo su -'.  And don't run su twice (SUDO_USER needs to contain your username)."
  exit 1
fi

echo "."
read -sp "User <$username> will be used to load objects in ElasticSearch. Please enter the password for $username: " -r passwd </dev/tty
echo

# Ensure the password provided is valid
space_list=$(curl -k --silent -u "${username}:${passwd}" "https://${kibana}/api/spaces/space" --write-out '%{http_code}')
retval=${space_list: -3}
if [[ $retval != 200 ]]; then
  echo "Unable to communicate with Kibana. Did you enter your password correctly?"
  echo "Script aborted, please try again."
  echo
  echo "Usage: "
  echo "   For Elastic upgrades (prompts for password): "
  echo "       curl -s -k https://satrepo/pulp/content/oadcgs/Library/custom/Elastic_Client/Elastic_Files/install/create_spaces.sh | bash "
  echo
  exit 1
fi

#Create CyberOps Space
if ! echo "$space_list" | grep -q "cyberops"; then
  echo "Creating space: CyberOps"
  curl -k -XPOST -s -u "$username":"$passwd" https://${kibana}/api/spaces/space -H "kbn-xsrf:true" -H "Content-Type: application/json" -d'
      {
        "id":"cyberops",
        "name":"CyberOps",
        "description":"CyberOps space",
        "initials":"Cy",
        "color":"#0000FF",
        "disabledFeatures":[]
      }'
  echo
else
  echo "CyberOps space already exists, not creating."
  echo
fi

#Create Site Spaces
# Settings for LDAP queries
mysite=${site^^}
serviceAcct="${site_num}_elastic.svc"
myrealm=$(realm list --name-only)
IFS='.' read -r -a dnArray <<<"$myrealm"
dnstr=""
for dn in "${dnArray[@]}"; do
  if [ -z "$dnstr" ]; then
    dnstr="dc=$dn"
  else
    dnstr="$dnstr,dc=$dn"
  fi
done
if ! command -v ldapsearch &>/dev/null; then
  echo "ldapsearch command is needed to run this script, attempting to install..."
  yum -y install openldap-clients

  if ! command -v ldapsearch &>/dev/null; then
    echo
    echo "Installation of openldap-clients failed, ldapsearch is needed to execute this script"
    echo "Contact a Linux Admin for assistance with loading openldap-clients on this machine"
    echo
    exit 1
  fi
fi

# Download site.yml to a temporary file
sites_file=$(mktemp)
if ! curl -s -o "$sites_file" "https://$fileloc/install/sites.yml"; then
  echo
  echo "Unable to download sites.yml. Script aborted."
  exit 1
fi

# Determine environment based on hostname first 3 characters
case "$hostname" in
U00* | U0A*)
  echo -n "Detected UNCLASSIFIED environment, loading spaces:"
  env="UNCLASS"
  ;;
S24* | S70* | SR0*)
  echo
  read -r -p "Detected CTE Low / MTE Low environment, enter environment (CTEL or MTEL): " env
  env=${env^^} # converts input to uppercase
  if [[ "$env" == "MTEL" || "$env" == "CTEL" ]]; then
    echo "Using ${env} environment, loading spaces:"
  else
    echo "Invalid input. Expected 'CTEL' or 'MTEL'. Script aborted." >&2
    exit 1
  fi
  ;;
T24* | T70* | TR0*)
  echo
  read -r -p "Detected CTE High / MTE High environment, enter environment (CTEH or MTEH): " env
  env=${env^^} # converts input to uppercase
  if [[ "$env" == "MTEH" || "$env" == "CTEH" ]]; then
    echo "Using ${env} environment, loading spaces:"
  else
    echo "Invalid input. Expected 'CTEH' or 'MTEH'. Script aborted." >&2
    exit 1
  fi
  ;;
S00* | S0A*)
  echo -n "Detected SECRET environment, loading spaces:"
  echo
  env="LOW"
  ;;
T00* | T0A*)
  echo -n "Detected TS/SCI environment, loading spaces:"
  echo
  env="HIGH"
  ;;
SD1* | SD2*)
  echo -n "Detected REL Low environment, loading spaces:"
  echo
  env="RELL"
  ;;
TD1* | TD2*)
  echo -n "Detected REL High environment, loading spaces:"
  echo
  env="RELH"
  ;;
*)
  echo "Unknown environment for hostname $hostname. Script aborted." >&2
  exit 1
  ;;
esac

# Read site names from sites.yml
declare -A site_names
while IFS=: read -r f1 f2; do
  if [ ! "$f2" == "" ]; then
    v1=$(echo "$f1" | awk '{$1=$1};1')
    site_names["$v1"]=$(echo "$f2" | awk '{$1=$1};1')
  fi
done <"$sites_file"

# Set up the site data for each environment
declare -A envs=(
  ["UNCLASS"]="00 0a 01 02"
  ["CTEL"]="24 70 r0"
  ["CTEH"]="24 70 r0"
  ["MTEL"]="24"
  ["MTEH"]="24"
  ["RELL"]="d1 d2"
  ["RELH"]="d1 d2"
  ["LOW"]="00 0a 01 02 03 04 05 13 14 15 16 17 19 50 69"
  ["HIGH"]="00 0a 01 02 03 04 05 16 17 18 19 21 22 23 45 49 69"
)

# Define colors for site initials
declare -A site_color=(
  ["0a"]="#01FF70"
  ["00"]="#B10DC9"
  ["01"]="#FF851B"
  ["02"]="#E74C3C"
  ["03"]="#9B59B6"
  ["04"]="#2E86C1"
  ["05"]="#2E4053"
  ["13"]="#F5B041"
  ["14"]="#7D6608"
  ["15"]="#117A65"
  ["16"]="#A04000"
  ["17"]="#F1948A"
  ["18"]="#6A5ACD"
  ["19"]="#BB8FCE"
  ["21"]="#00FF7F"
  ["22"]="#9400D3"
  ["23"]="#8B008B"
  ["24"]="#FF5733"
  ["26"]="#0074D9"
  ["45"]="#7B241C"
  ["49"]="#808000"
  ["50"]="#D2B4DE"
  ["69"]="#6F4E37"
  ["70"]="#FF4136"
  ["76"]="#2ECC40"
  ["d1"]="#7FDBFF"
  ["d2"]="#F012BE"
  ["r0"]="#FFDC00"
)

Missing_Sites=""
Space_Names=""
# Loop through the sites and perform actions for each site
for site in ${envs["$env"]}; do
  initials="$site"
  name="${site_names["$site"]}"
  if [[ -z "$name" ]]; then
    echo "Unknown site ID: $site"
    Missing_Sites="${Missing_Sites} ${site}"
    continue
  fi
  space_id="$initials"

  # Create the site space
  if ! echo "$space_list" | grep -q "$space_id"; then
    echo "Creating space: ${name} (${initials})"
    curl -k -XPOST -s -u "$username":"$passwd" https://${kibana}/api/spaces/space -H "kbn-xsrf:true" -H "Content-Type: application/json" -d'
    {
      "id":"'"$space_id"'",
      "name":"'"$name"'",
      "description":"'"$name"' space",
      "initials":"'"$initials"'",
      "color":"'"${site_color["$initials"]}"'",
      "disabledFeatures":[]
    }'
    echo
  else
    echo "$space_id space already exists, not creating."
    echo
  fi

  # Define Kibana Admin Role for the site
  echo "Creating Roles for ${initials}_Kibana_Admin at site $name"
  rolename="${initials}_kibana_admin"
  curl -XPUT -s -u "${username}":"${passwd}" "https://${ES_HOST}:${ES_PORT}/_security/role/${rolename}" -H "Content-Type: application/json" -d'
  {
    "cluster": [],
    "indices": [],
    "applications": [
      {
        "application": "kibana-.kibana",
        "privileges": [
          "feature_discover.all",
          "feature_visualize.all",
          "feature_dashboard.all",
          "feature_canvas.all",
          "feature_maps.all",
          "feature_infrastructure.all",
          "feature_logs.all",
          "feature_uptime.all",
          "feature_apm.read",
          "feature_graph.all",
          "feature_dev_tools.all",
          "feature_advancedSettings.all",
          "feature_indexPatterns.all",
          "feature_savedObjectsManagement.all",
          "feature_ingestManager.all",
          "feature_ml.all",
          "feature_observabilityCases.all"
        ],
        "resources": [
          "space:'"$space_id"'"
        ]
      }
    ],
    "run_as": [],
    "metadata": {},
    "transient_metadata": {
      "enabled": true
    }
  }'
  echo

  # Define Kibana Admin Role Mapping for the site
  kibana_name="${initials}_kibana_admin"
  group_name="${initials} kibana admins"
  echo "Map Kibana role $kibana_name to LDAP group $group_name"
  dname=$(runuser -l "$serviceAcct" -c "ldapsearch -LLL -H \"ldap://${mysite}sm00dc01 ldap://${mysite}sm01dc02\" -b $dnstr -Y=GSSAPI '(&(objectClass=group)(cn=$group_name))'  dn " | sed ':a;N;$!ba;s/\n //g' | awk -F '# refldap' '{print $1}' | cut -d':' -f2-)
  echo
  echo "LDAP group $group_name : $dname"

  echo "Creating role mapping for ${kibana_name} (${name})"
  if ! curl -k --silent -u "${username}":"${passwd}" -X POST "https://${ES_HOST}:${ES_PORT}/_security/role_mapping/${kibana_name}" -H 'Content-Type: application/json' -d @- <<EOF; then
      {
        "enabled": true,
        "roles": [
          "${kibana_name}"
        ],
        "rules": {
          "all": [
            {
              "field": {
                "groups": "$dname"
              }
            }
          ]
        },
        "metadata": {}
      }
EOF

    echo
    echo "Failed to create role mapping for ${group_name}"
  fi
  echo

  if [ -z "${Space_Names}" ]; then
    Space_Names="\"space:${site}\""
  else
    Space_Names="${Space_Names}, \"space:${site}\""
  fi

done

#Add site spaces as read-only to the dcgs_site_user role.
# Role is created (w/o content) in load_roles.sh
# Role is added to dcgs_kibana_user role mapping in create_role_mappings.sh.

rolename="dcgs_site_user"
echo -en "\nUpdating role: $rolename with spaces: $Space_Names"
curl -XPUT -s -u "${username}":"${passwd}" https://${ES_HOST}:${ES_PORT}/_security/role/${rolename} -H "Content-Type: application/json" -d'
{
    "applications" : [
      {
        "application" : "kibana-.kibana",
        "privileges" : [
          "feature_discover.read",
          "feature_dashboard.read",
          "feature_visualize.read",
          "feature_canvas.read",
          "feature_maps.read",
          "feature_infrastructure.read",
          "feature_logs.read",
          "feature_uptime.read",
          "feature_graph.read",
          "feature_dev_tools.read",
          "feature_indexPatterns.read",
          "feature_savedObjectsManagement.read",
          "feature_advancedSettings.read",
          "feature_ingestManager.read",
          "feature_ml.read",
          "feature_observabilityCases.all",
          "feature_apm.read",
          "feature_savedObjectsTagging.read"
        ],
        "resources" : [
          '"${Space_Names}"'
        ]
      }
    ]
}
'

echo
if [ -z "$Missing_Sites" ]; then
  echo "Loading of Spaces Complete!"
else
  echo "======== Unknown site(s): ${Missing_Sites} ========"
  echo "Site(s) were not found in sites.yml, spaces were not created for them."
fi
echo

# Clean up temporary file
rm -f "$sites_file"
