#!/bin/bash
#			    Unclassified
#
#########################################################################

#
# Initilize variables
#
logsysconfig="/etc/sysconfig/logstash"
user=$SUDO_USER
ES_HOST="elastic-node-1"
ES_PORT="9200"
snum=$(hostname | cut -c 2-3)

# Function: createaliases
# Parameters: Index with site number ${bsindex}
# Desc: Create alias for bootstrapped indexes
function createaliases() {
  alias=$(curl -w 'return_code=%{http_code}\n' --silent -k -XGET -u "${user}":"${passwd}" "https://${ES_HOST}.${clusterSite}:${ES_PORT}/_cat/aliases/$1")
  retcode=$(echo "$alias" | awk -F 'return_code=' '{print $2}' | sed '/^$/d')
  if [ "$retcode" == "200" ]; then
    # Ensure there is an is_write alias
    alias=$(echo "$alias" | awk -F 'return_code' '{print $1}' | sed '/^$/d' | grep "true")

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

# Function: deleteoldtemplates
# Parameters: Index with site number ${bsindex}
# Desc: Delete legacy templates
function deleteoldtemplates() {
  old_index=$(curl -k -XGET -u "${user}":"${passwd}" "https://${ES_HOST}.${clusterSite}:${ES_PORT}/_template/est_${1}?pretty" --write-out '%{http_code}' --silent)

  retval=${old_index: -3}
  if [[ $retval == 200 ]]; then
    echo ""
    echo "Deleting legacy index template: est_${1}"
    echo ""
    curl --silent -k -XDELETE -u "${user}":"${passwd}" "https://${ES_HOST}.${clusterSite}:${ES_PORT}/_template/est_${1}?pretty"
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
  indexes=(metricbeat-8.6.2 metricbeat-"${bsver}" dcgs-syslog-iaas-ent dcgs-audits_syslog-iaas-ent dcgs-syslog_loginsight-iaas-ent)

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

      if [ "${indexname}" == "syslog" ] || [ "${indexname}" == "syslog_loginsight" ]; then
        componentname="syslog"
        addons=", \"estc_dcgs_app_defaults\", \"estc_syslog-settings\""
      fi

      if [ "${indexname}" == "audits_syslog" ]; then
        addons=", \"estc_loginsight-agent-mappings\", \"estc_audits_syslog-settings\""
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
    echo "deleting old templates..."
    deleteoldtemplates "${bsindex}"

  done
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

if [ -z "$1" ]; then
  echo
  read -p "Enter site of Elastic cluster this Logstash will send to(ex: ech, isec). default [ech] :" -r clusterSite </dev/tty
  clusterSite=${clusterSite:-ech}
  echo
else
  clusterSite=$1
fi

# Ensure password provided is valid
pwcheck=$(curl -k --silent -u "${user}":"${passwd}" "https://${ES_HOST}.${clusterSite}:${ES_PORT}/_cluster/health" --write-out '%{http_code}')
retval=${pwcheck: -3}
if [[ $retval != 200 ]]; then
  echo
  echo "Unable to communicate with Elasticsearch. Did you enter your password correctly?"
  echo "Script aborted, please try again."
  echo
  exit
fi

#
# bootstrap indexes and create aliases
#
bootstrapindexes

echo
echo "bootstrapping complete."
echo

#################################################################################
#
#			    Unclassified
#
#################################################################################
