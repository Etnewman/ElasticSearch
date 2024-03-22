#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Loads Elastic to AD role mappings
#
# Tracking #: CR-2020-OADCGS-086
#
# File name: load_role_mappings.sh
#
# Note: SAKM must be installed and configured for the elastic
#       service account for this script to be successful
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, date it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2020-OADCGS-086, Steve Truxal, 2020-07-31: Original Version
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

ES_HOST="elastic-node-1"
ES_PORT="9200"

if [ -n "$1" ] && [ "$1" == "install" ]; then
  # Initial setup will used static password
  username="elastic"
  passwd="elastic"
  action="Creating"
else
  username=$SUDO_USER
  action="Updating"

  echo "."
  read -sp "User <$username> will be used for interaction with elastic, please enter the password for $username: " -r passwd </dev/tty
  echo
fi

# Ensure password provided is valid
pwcheck=$(curl -k --silent -u "${username}":"${passwd}" "https://${ES_HOST}:${ES_PORT}/_cluster/health" --write-out '%{http_code}')
retval=${pwcheck: -3}
if [[ $retval != 200 ]]; then
  echo
  echo "Unable to communcate with Elasticsearch. Password incorrect or improper usage."
  echo "Script aborted, please try again."
  echo
  echo "Usage: "
  echo "   For fresh installs: "
  echo "       curl -s -k https://xxsu01ro01.$(hostname -d)/yum/elastic/install/load_role_mappings.sh | bash -s install"
  echo
  echo "   For upgrades: "
  echo "       curl -s -k https://xxsu01ro01.$(hostname -d)/yum/elastic/install/load_role_mappings.sh | bash "
  echo
  exit
fi

# Get Site to build DC names
mysite=$(hostname | cut -c 1-3)
mysite=${mysite^^}

# Build service account name
serviceAcct="$(hostname | cut -c 2,3)_elastic.svc"

# Build searchbase
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
  fi
fi

dname=$(runuser -l "$serviceAcct" -c "ldapsearch -LLL -H \"ldap://${mysite}sm00dc01 ldap://${mysite}sm01dc02\" -b $dnstr -Y=GSSAPI '(&(objectClass=group)(cn=ent Elastic Admins))'  dn " | sed ':a;N;$!ba;s/\n //g' | awk -F '# refldap' '{print $1}' | cut -d':' -f2-)

rolemapping="dcgs_ent_elastic_admin"
echo -en "\n${action} role_mapping: $rolemapping, dname=$dname\n"
curl -XPUT -s -u "${username}":"${passwd}" https://${ES_HOST}:${ES_PORT}/_security/role_mapping/${rolemapping} -H "Content-Type: application/json" -d'
{
    "enabled" : true,
    "roles" : [
      "superuser"
    ],
    "rules" : {
      "all" : [
        {
          "field" : {
            "groups" : "'"$dname"'"
          }
        }
      ]
    },
    "metadata" : { }
}
'

dname=$(runuser -l "$serviceAcct" -c "ldapsearch -LLL -H \"ldap://${mysite}sm00dc01 ldap://${mysite}sm01dc02\" -b $dnstr -Y=GSSAPI '(&(objectClass=group)(cn=ent Kibana Admins))'  dn " | sed ':a;N;$!ba;s/\n //g' | awk -F '# refldap' '{print $1}' | cut -d':' -f2-)
rolemapping="dcgs_junior_kibana_admin"
echo -en "\n${action} role_mapping: $rolemapping, dname=$dname\n"
curl -XPUT -s -u "${username}":"${passwd}" https://${ES_HOST}:${ES_PORT}/_security/role_mapping/${rolemapping} -H "Content-Type: application/json" -d'
{
    "enabled" : true,
    "roles" : [
      "dcgs_junior_kibana_admin",
      "kibana_admin",
      "machine_learning_admin",
      "monitoring_user",
      "rollup_user",
      "snapshot_user",
      "watcher_admin"
    ],
    "rules" : {
      "all" : [
        {
          "field" : {
            "groups" : "'"$dname"'"
          }
        }
      ]
    },
    "metadata" : { }
}
'

dname=$(runuser -l "$serviceAcct" -c "ldapsearch -LLL -H \"ldap://${mysite}sm00dc01 ldap://${mysite}sm01dc02\" -b $dnstr -Y=GSSAPI '(&(objectClass=group)(cn=DCGS Priv Users))'  dn " | sed ':a;N;$!ba;s/\n //g' | awk -F '# refldap' '{print $1}' | cut -d':' -f2- | sed 's/ent/*/g')

rolemapping="dcgs_kibana_user"
echo -en "\n${action} role_mapping: $rolemapping, dname=$dname\n"
curl -XPUT -s -u "${username}":"${passwd}" https://${ES_HOST}:${ES_PORT}/_security/role_mapping/${rolemapping} -H "Content-Type: application/json" -d'
{
    "enabled" : true,
    "roles" : [
      "dcgs_kibana_user",
      "dcgs_site_user",
      "machine_learning_user",
      "monitoring_user",
      "watcher_user"
    ],
    "rules" : {
      "all" : [
        {
          "field" : {
            "groups" : "'"$dname"'"
          }
        }
      ]
    },
    "metadata" : { }
}
'

dname1=$(runuser -l "$serviceAcct" -c "ldapsearch -LLL -H \"ldap://${mysite}sm00dc01 ldap://${mysite}sm01dc02\" -b $dnstr -Y=GSSAPI '(&(objectClass=group)(cn=ent DCGS ISSM))'  dn " | sed ':a;N;$!ba;s/\n //g' | awk -F '# refldap' '{print $1}' | cut -d':' -f2-)
dname2=$(runuser -l "$serviceAcct" -c "ldapsearch -LLL -H \"ldap://${mysite}sm00dc01 ldap://${mysite}sm01dc02\" -b $dnstr -Y=GSSAPI '(&(objectClass=group)(cn=ent DCGS ISSOs))'  dn " | sed ':a;N;$!ba;s/\n //g' | awk -F '# refldap' '{print $1}' | cut -d':' -f2-)
rolemapping="dcgs_cyber_user"
echo -en "\n${action} role_mapping: $rolemapping\n"
echo "dname1=$dname1"
echo "dname2=$dname2"
curl -XPUT -s -u "${username}":"${passwd}" https://${ES_HOST}:${ES_PORT}/_security/role_mapping/${rolemapping} -H "Content-Type: application/json" -d'
{
    "enabled" : true,
    "roles" : [
      "dcgs_cyber_user",
      "machine_learning_user",
      "monitoring_user",
      "watcher_user"
    ],
    "rules" : {
      "all" : [
        {
          "field" : {
            "groups" : [
              "'"${dname1}"'",
              "'"${dname2}"'"
            ]
          }
        }
      ]
    },
    "metadata" : { }
}
'

dname1=$(runuser -l "$serviceAcct" -c "ldapsearch -LLL -H \"ldap://${mysite}sm00dc01 ldap://${mysite}sm01dc02\" -b $dnstr -Y=GSSAPI '(&(objectClass=group)(cn=ent CyAN System Admins))'  dn " | sed ':a;N;$!ba;s/\n //g' | awk -F '# refldap' '{print $1}' | cut -d':' -f2-)
dname2=$(runuser -l "$serviceAcct" -c "ldapsearch -LLL -H \"ldap://${mysite}sm00dc01 ldap://${mysite}sm01dc02\" -b $dnstr -Y=GSSAPI '(&(objectClass=group)(cn=ent CyAN Report Editor))'  dn " | sed ':a;N;$!ba;s/\n //g' | awk -F '# refldap' '{print $1}' | cut -d':' -f2-)

rolemapping="dcgs_cyan_admin"
echo -en "\n${action} role_mapping: $rolemapping\n"
echo "dname1=$dname1"
echo "dname2=$dname2"
curl -XPUT -s -u "${username}":"${passwd}" https://${ES_HOST}:${ES_PORT}/_security/role_mapping/${rolemapping} -H "Content-Type: application/json" -d'
{
    "enabled" : true,
    "roles" : [
      "dcgs_cyan_admin",
      "machine_learning_admin",
      "monitoring_user",
      "watcher_user"
    ],
    "rules" : {
      "all" : [
        {
          "field" : {
            "groups" : [
              "'"${dname1}"'",
              "'"${dname2}"'"
            ]
          }
        }
      ]
    },
    "metadata" : { }
}
'

dname=$(runuser -l "$serviceAcct" -c "ldapsearch -LLL -H \"ldap://${mysite}sm00dc01 ldap://${mysite}sm01dc02\" -b $dnstr -Y=GSSAPI '(&(objectClass=group)(cn=ent CyAN Report Viewer))'  dn " | sed ':a;N;$!ba;s/\n //g' | awk -F '# refldap' '{print $1}' | cut -d':' -f2-)

rolemapping="dcgs_cyan_user"
echo -en "\n${action} role_mapping: $rolemapping, dname=$dname"
curl -XPUT -s -u "${username}":"${passwd}" https://${ES_HOST}:${ES_PORT}/_security/role_mapping/${rolemapping} -H "Content-Type: application/json" -d'
{
    "enabled" : true,
    "roles" : [
      "dcgs_cyan_user"
    ],
    "rules" : {
      "all" : [
        {
          "field" : {
            "groups" : "'"${dname}"'"
          }
        }
      ]
    },
    "metadata" : { }
}
'

echo -e "\n\n*** Script Complete ***"
#################################################################################
#
#			    Unclassified
#
#################################################################################
