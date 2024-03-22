#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Creates Public Key Infrastructure(PKI) req, keys and Certificate
#          Signing Requests(CSRs) for Logstash instances
#
# Tracking #: CR-2020-OADCGS-086
#
# File name: make_logstash_csr.sh
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
  site=$(hostname -d | cut -f1 -d".")

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
subjectAltName = DNS: $1.$dom, DNS:$1, DNS:logstash-$2.$site, DNS:$1.$site, DNS:logstash-$2, DNS:logstash

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

  gen_csr "$1" "$2"
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

#
# Main begins here
#
site=$(hostname | cut -c 1-3)
create_dirs
lsname="${site}su01ls01"
cert_req "$lsname" "$site"

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
echo " in the elastic repos install/certs directory"
echo
echo "********************  PKI Certificate Requests Created  ***************"
#################################################################################
#
#			    Unclassified
#
#################################################################################
