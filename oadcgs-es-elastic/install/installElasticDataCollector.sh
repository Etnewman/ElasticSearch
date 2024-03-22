#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Used to install ElasticDataCollector Service on Logstash Instance
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: installElasticDataCollector.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Steve Truxal, 2021-03-15: Original Version
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
modules=("pip-21.3.1-py3-none-any.whl"
  "idna-3.3-py3-none-any.whl"
  "pycparser-2.21-py2.py3-none-any.whl"
  "cffi-1.15.0-cp36-cp36m-manylinux_2_5_x86_64.manylinux1_x86_64.whl"
  "six-1.16.0-py2.py3-none-any.whl"
  "certifi-2021.10.8-py2.py3-none-any.whl"
  "charset_normalizer-2.0.12-py3-none-any.whl"
  "urllib3-1.26.9-py2.py3-none-any.whl"
  "cryptography-37.0.2-cp36-abi3-manylinux_2_12_x86_64.manylinux2010_x86_64.whl"
  "requests-2.27.1-py2.py3-none-any.whl"
  "elasticsearch-8.9.0-py3-none-any.whl"
  "pyvmomi-7.0.3-py2.py3-none-any.whl"
  "setproctitle-1.2.3-cp36-cp36m-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
  "configparser-5.2.0-py3-none-any.whl"
  "ply-3.11-py2.py3-none-any.whl"
  "pycryptodomex-3.14.1-cp35-abi3-manylinux1_x86_64.whl"
  "pyasn1-0.4.8-py2.py3-none-any.whl"
  "pysmi-0.3.4-py2.py3-none-any.whl"
  "pysnmp-4.4.12-py2.py3-none-any.whl"
  "arrow-1.2.2-py3-none-any.whl"
  "python_dateutil-2.8.2-py2.py3-none-any.whl"
  "pyTenable-1.4.7-py3-none-any.whl"
  "restfly-1.4.6-py3-none-any.whl"
  "typing_extensions-4.1.1-py3-none-any.whl"
  "python_box-6.0.2-py3-none-any.whl"
  "semver-2.13.0-py2.py3-none-any.whl"
  "dataclasses-0.8-py3-none-any.whl"
  "elastic_transport-8.4.0-py3-none-any.whl"
)

# Let's make sure root is executing the script
if [[ $EUID -ne 0 ]]; then
  echo
  echo "***************** Install Failed **************************"
  echo "*                                                         *"
  echo "*  You must be root to install the elasticDataCollector   *"
  echo "*                                                         *"
  echo "***************** Install Failed **************************"
  echo
  exit 1
fi

#
# Initilize variables
#

fileloc="satrepo/pulp/content/oadcgs/Library/custom/Elastic_Client/Elastic_Files"

scriptDir="/etc/logstash/scripts"
scriptDataDir="${scriptDir}/data"
scriptTar="elasticDataCollector.tar"
pyModulesTar="python3_modules.tar"

mibDir="${scriptDir}/MIBS"
mibTar="pysnmp_device_mibs.tar"
staging="PYSTAGING"

workBaseDir="/ELK-local"
workDirs=("device_data" "metrics_out" "elasticDataCollector")

user=$SUDO_USER

echo "."
read -sp "User <$user> will be used for interaction with elastic, please enter the password for $user: " -r passwd </dev/tty
echo

#
# Query site(s) of Elastic Cluster, needed for Querier
#
clusterSites=()
echo
read -p "Enter the primary Elastic cluster this Data Collector will query data from(ex: ech, wch, isec). default [ech]: " -r clusterSite </dev/tty
clusterSite=${clusterSite:-ech}
clusterSites+=("$clusterSite")
echo

if [[ "${clusterSites[0]}" == "ech" ]]; then
  echo
  echo "Setting secondary cluster to wch..."
  clusterSites+=("wch")
  echo
fi

# Ensure password provided is valid for all cluster(s)
for clusterSite in "${clusterSites[@]}"; do
  if [ -n "$clusterSite" ]; then
    pwcheck=$(curl -k --silent -u "${user}":"${passwd}" "https://elastic-node-1.$clusterSite:9200/_cluster/health" --write-out '%{http_code}')
    retval=${pwcheck: -3}
    if [[ $retval != 200 ]]; then
      echo
      echo "Unable to communcate with ""$clusterSite"" Elasticsearch. Did you enter your password correctly?"
      echo "Script aborted, please try again."
      echo
      exit
    fi
  fi
done

# Get number of nodes in the primary cluster
numNodes=$(curl -k --silent -XGET -u "${user}":"${passwd}" "https://elastic-node-1.""${clusterSites[0]}"":9200/_cat/nodes?pretty" | wc -l)

### Create clusterOutputs.dat file
case $numNodes in
3)
  out1=1
  out2=2
  out3=3
  ;;
7)
  out1=1
  out2=2
  out3=3
  ;;
10)
  out1=5
  out2=6
  out3=7
  ;;
15)
  out1=6
  out2=7
  out3=8
  ;;
*)
  echo "Unsupported Cluster size for DCGS: $numNodes"
  exit
  ;;
esac

if [[ ! -e "${scriptDataDir}/clusterOutputs.dat" ]]; then
  cat <<EOF >$scriptDataDir/clusterOutputs.dat
OUTPUT1:elastic-node-${out1}
OUTPUT2:elastic-node-${out2}
OUTPUT3:elastic-node-${out3}
EOF
fi

# Querier User for site to set in Kibana
site=$(hostname | cut -c 2-3)
quser="querier-$site"

# Ensure needed python modules are installed
echo "Ensuring needed python modules are loaded..."
yum -y install python3
yum -y install python3-wheel
yum -y install python3-tkinter

echo "Setting up python virutal env"
curl --silent -k https://"$fileloc"/install/artifacts/$pyModulesTar >/tmp/$pyModulesTar
mkdir /tmp/$staging
tar xf /tmp/$pyModulesTar -C /tmp/$staging

# stop elasticDataCollector if already installed and running
if (systemctl is-active --quiet elasticDataCollector); then
  systemctl stop elasticDataCollector
fi

# Ensure script and data directories exist
hadDataDir="false"
if [ -d $scriptDir ]; then
  if [ -d $scriptDataDir ]; then
    hadDataDir="true"
  fi
  # elasticDataCollector already installed back it up
  # remove existing backup if that already exists
  if [ -d "${scriptDir}.backup" ]; then
    rm -rf "${scriptDir}.backup"
  fi
  mv $scriptDir "${scriptDir}.backup"
fi

mkdir $scriptDir

# Ensure script data directory exists
mkdir $scriptDataDir
if [ $hadDataDir == "true" ]; then
  cp -p "${scriptDir}".backup/data/* $scriptDataDir
fi

# Create python virutalenv in script directory
cd $scriptDir || exit
python3 -m venv --system-site-packages venv

for module in "${modules[@]}"; do
  echo "Installing $module"
  $scriptDir/venv/bin/python -m wheel install --force /tmp/$staging/"$module"
done

rm -rf /tmp/$staging
rm /tmp/$pyModulesTar

echo "Installing ESS Elastic Data Collector..."

#Pull over elasticDataCollector tar file
curl --silent -k https://"$fileloc"/install/artifacts/$scriptTar >/tmp/$scriptTar

# Extract Device Collector
tar xf /tmp/$scriptTar -C $scriptDir
rm /tmp/$scriptTar

# Check to see if vsphere data file already exists
# if not then query for service account password needed for vsphere qpi queries
if [ ! -f "$scriptDataDir/vsphere.dat" ]; then
  $scriptDir/venv/bin/python $scriptDir/updatepasswd.py
fi

echo "Installing SNMP MIB files..."
#Pull over MIB tar file
curl --silent -k https://"$fileloc"/install/artifacts/$mibTar >/tmp/$mibTar

#Ensure MIB directory exists
if [ ! -d $mibDir ]; then
  mkdir $mibDir
fi

# Extract MIBs
tar xf /tmp/$mibTar -C $mibDir
rm /tmp/$mibTar

#install elasticDataCollector service
echo "Installing elasticDataCollector service..."
curl --silent -k https://"$fileloc"/install/artifacts/elasticDataCollector.service >/etc/systemd/system/elasticDataCollector.service
systemctl daemon-reload
systemctl enable elasticDataCollector

# Update MIB file permissions
chown -R root:logstash $scriptDir
chmod 755 $scriptDir/install
chmod 755 $mibDir
chmod 755 $scriptDataDir

# Update shell file ownership and permissions
chmod 755 $scriptDir/shell
chmod 755 $scriptDir/shell/hbssdlp.bash
chown -R root:logstash $scriptDir/shell
touch $scriptDataDir/hbssdlp.last_event_querytime
chmod 664 $scriptDataDir/hbssdlp.last_event_querytime

echo "Ensuring Work directories exists"
#Ensure output directory exists
if [ ! -d $workBaseDir ]; then
  mkdir $workBaseDir
fi

for dir in "${workDirs[@]}"; do
  if [ ! -d "$workBaseDir/$dir" ]; then
    mkdir "$workBaseDir/$dir"
  fi
done

# Copy ini files to ELK-local but don't overwrite if already there
if [ ! -f $workBaseDir/elasticDataCollector/appsconfig.ini ]; then
  if [ "$site" == "00" ]; then
    cp $scriptDir/install/appsconfig.ini $workBaseDir/elasticDataCollector/
  else
    cp $scriptDir/install/appsconfig-site.ini $workBaseDir/elasticDataCollector/appsconfig.ini
  fi
fi

if [ ! -f $workBaseDir/elasticDataCollector/groups.ini ]; then
  cp $scriptDir/install/groups.ini $workBaseDir/elasticDataCollector/
fi

# Generate random password for querier user
pass=$(tr -cd '[:alnum:]' </dev/urandom | fold -w15 | head -n1)

###### Bootstrap User for Querier
# First check to see if user already exists in all cluster(s)
for clusterSite in "${clusterSites[@]}"; do
  if [ -n "$clusterSite" ]; then
    returned_user=$(curl -k -u "$user":"$passwd" https://elastic-node-1."$clusterSite":9200/_security/user/"$quser")
    if [ "$returned_user" == "{}" ]; then
      echo "User does not exist, create it"
      curl -k -u "$user":"$passwd" -XPOST -H 'Content-Type: application/json' "https://elastic-node-1.$clusterSite:9200/_security/user/$quser" -d "{\"password\":\"$pass\",\"roles\": \"dcgs_kibana_user\", \"full_name\" : \"Data Collector\"}"
    else
      echo "User exists, Just update password"
      curl -k -u "$user":"$passwd" -XPUT -H 'Content-Type: application/json' "https://elastic-node-1.$clusterSite:9200/_security/user/$quser/_password" -d "{\"password\":\"$pass\"}"
    fi
  fi
  # map stale-delete role to site querier user
  rolename="stale-delete"
  current_roles=$(curl -k --silent -XGET -u "$user":"$passwd" https://elastic-node-1:9200/_security/user/"$quser" -H "kbn-xsrf: reporting" | sed 's/^.*\(":\[\".*]\).*$/\1/' | sed 's/^..//')
  if [[ "$current_roles" != *"$rolename"* ]]; then
    new_roles=${current_roles:0:-1},\"${rolename}\"]
    echo
    echo "Assigning $rolename role to $quser"
    echo
    curl -k -XPUT -s -u "$user":"$passwd" https://elastic-node-1:9200/_security/user/"$quser" -H "Content-Type: application/json" -d'
    {
      "roles" : '"$new_roles"'
    }
    '
  fi
done

# Encrypt the password and save it for use by Querier
cryptPass=$($scriptDir/venv/bin/python $scriptDir/Crypt.py -e "$pass")
echo "${quser}:${cryptPass}" >"${scriptDataDir}/querier.dat"

# Create clusterSite.dat file
echo "PRIMARY:${clusterSites[0]}" >"${scriptDataDir}/clusterSites.dat"
if [ -n "${clusterSites[1]}" ]; then
  echo "SECONDARY:${clusterSites[1]}" >>"${scriptDataDir}/clusterSites.dat"
fi

# Activate Cron Cleanup for Stale-Delete
cp $scriptDir/crons/cleanup.cron /etc/cron.daily/cleanup.cron
chmod +x /etc/cron.daily/cleanup.cron

# Clean up old files
# Previous versions of the data collector were using data files in the scripts directory
# and also writing data files to the / directory. The new version uses the data directory
# in the scripts folder to hold all of these files. This portion of the script will
# move files in the old location to the new and also delete any leftover files
if [ -f "/xtremio.last_event_querytime" ]; then
  mv "/xtremio.last_event_querytime" $scriptDataDir
fi

if [ -f "/vsphere.last_event_querytime" ]; then
  mv "/vsphere.last_event_querytime" $scriptDataDir
fi

if [ -f "/lastupdate" ]; then
  mv /lastupdate $scriptDataDir/watcher.last_pos
fi

if [ -f $scriptDir/deviceconfig.json ]; then
  mv $scriptDir/deviceconfig.json $scriptDataDir
fi

rm -f $scriptDir/*.dat

# update SNMP timeouts to 5 seconds if deviceconfig file exists
if [ -f "$scriptDataDir/deviceconfig.json" ]; then
  sed -i '/timeout:*/c\            "timeout": 5000000,' $scriptDataDir/deviceconfig.json
fi

# Setup enviornment for configurator
touch "$HOME"/.Xauthority && chmod 600 "$HOME"/.Xauthority
yum -y install xauth

# Enable X11Forwarding
#puppet agent --disable
sed -i 's/X11Forwarding no/X11Forwarding yes/g' /etc/ssh/sshd_config
systemctl restart sshd

echo
echo "*********** Install Success ***********"
echo "*                                     *"
echo "* Device Collector Install Complete.  *"
echo "*                                     *"
echo "*********** Install Success ***********"
echo
echo "Starting Elastic Data Collector"
echo
systemctl start elasticDataCollector
#################################################################################
#
#			    Unclassified
#
#################################################################################
