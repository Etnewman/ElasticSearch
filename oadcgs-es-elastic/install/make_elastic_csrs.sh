#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Creates Public Key Infrastruture(PKI) req, keys and Certificate
#          Signing Requests(CSRs) for Elastic Nodes
#
# Tracking #: CR-2020-OADCGS-086
#
# File name: make_elastic_csrs.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, date it was revised,
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

gen_csr() {

  dom=$(hostname -d)
  dom1=$(hostname -d | cut -f1 -d".")

  if [ "$3" == "true" ]; then
    if [ "$4" == "0a" ]; then
      sans="DNS:$1.$dom, DNS:elastic-node-$2, DNS:$1 ,DNS:$1.$dom1, DNS:elastic-node-$2.$dom1, DNS:kibana, DNS: kibana.$dom1, DNS: kibana.$dom, DNS:kibana-wch, DNS: kibana-wch.$dom1, DNS: kibana-wch.$dom"
    else
      sans="DNS:$1.$dom, DNS:elastic-node-$2, DNS:$1 ,DNS:$1.$dom1, DNS:elastic-node-$2.$dom1, DNS:kibana, DNS: kibana.$dom1, DNS: kibana.$dom"
    fi
  else
    sans="DNS:$1.$dom, DNS:elastic-node-$2, DNS:$1 ,DNS:$1.$dom1, DNS:elastic-node-$2.$dom1"
  fi

  cat <<EOF >./reqs/"$1".req

[ req ]
default_bits = 2048
default_keyfile = $1.key
distinguished_name = req_distinguished_name
encrypt_key = no
prompt = no
string_mask = nombstr
req_extensions = v3_req

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment, dataEncipherment, nonRepudiation
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = $sans

[ req_distinguished_name ]
countryName = "US"
localityName = "Robins AFB"
stateOrProvinceName = "GA"
organizationName = "DCGS"
organizationalUnitName = "OADCGS"
commonName= $1.$dom
emailAddress = DCGS@DCGS.mil

EOF

}

cert_req() {

  gen_csr "$1" "$2" "$3" "$4"
  openssl req -new -newkey rsa:2048 -nodes -out ./csrs/"$1".csr -keyout ./keys/"$1".key -config ./reqs/"$1".req

}

create_dirs() {

  if [[ ! -d "./reqs" ]]; then
    mkdir reqs
  fi

  if [[ ! -d "./csrs" ]]; then
    mkdir csrs
  fi

  if [[ ! -d "./keys" ]]; then
    mkdir keys
  fi

}

test() {
  echo "Called with 1: $1  and 2: $2"
}

#
# Main begins here
#
site=$(hostname | cut -c 1-3)
sitenum=$(hostname | cut -c 2-3)

numNodes=0
while [[ ($numNodes -lt 1 || $numNodes -gt 3) ]]; do
  echo "How many Elasticsearch nodes will there be in this cluster?"
  echo "Options:"
  echo "   Enter 1 for 6 Nodes"
  echo "   Enter 2 for 10 Nodes"
  echo "   Enter 3 for 15 Nodes"
  read -p "Enter a value (1-3): " -r numNodes </dev/tty
  echo
done

if [ "$numNodes" = "1" ]; then
  echo "6 node cluster"
  nodes=6
  kibana_nodes=(5 6)

elif [ "$numNodes" = "2" ]; then
  echo "10 node cluster"
  nodes=10
  kibana_nodes=(7 10)

else
  echo "15 node cluster"
  nodes=15
  kibana_nodes=(10 15)
fi

create_dirs

START=1
for ((i = START; i <= nodes; i++)); do
  host="$(printf "%3ssu01el%02d" "$site" "$i")"
  kibana="false"
  for k in "${kibana_nodes[@]}"; do
    if [ "$k" == "$i" ]; then
      kibana="true"
    fi
  done
  cert_req "$host" "$i" "$kibana" "$sitenum"
done

echo
echo "********************  PKI Certificate Requests Created  ***************"
echo
echo "   - CSRs are located in the .\csrs directory"
echo "   - Keys for each node are located in the keys directory"
echo
echo " Use the CSRs to submit certificate requests with the appropriate "
echo " certificate authority. "
echo
echo " Once certificates have been obtained place the keys and the certificates "
echo " in the elastic repo certs directory"
echo
echo "********************  PKI Certificate Requests Created  ***************"
#################################################################################
#
#			    Unclassified
#
#################################################################################
