#!/bin/bash
#			    Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: Removes dashboards and visuals added in 7.9.1 install
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: remove_7.9.1_objects.sh
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, date it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Steve Truxal, 2021-03-22: Original Version
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
# Initilize variables
#
user=$SUDO_USER

dashboards=(4db49bb0-bc7c-11ea-8272-65cce4870ea0 65441040-6924-11ea-a18f-d31ef66e5966 6803f900-accf-11ea-a01f-f320212f1d0e 6ccc8ac0-e96e-11ea-94be-03f2e357123b 7d0cc6b0-5e2d-11ea-aafb-371a1379ec5c Winlogbeat-Dashboard-ecs b4048340-55ce-11ea-af72-73b5538b92f5 d2cc1040-531c-11ea-af72-73b5538b92f5 dfc03010-689d-11ea-a18f-d31ef66e5966 fdae41b0-4f5d-11ea-af72-73b5538b92f5 45ddbe80-e896-11ea-94be-03f2e357123b)

visuals=(57b8b300-52b2-11ea-af72-73b5538b92f5 2dde62b0-52a2-11ea-af72-73b5538b92f5 2f964ac0-eb93-11ea-94be-03f2e357123b 9ffd83c0-52a3-11ea-af72-73b5538b92f5 cfe80160-5293-11ea-af72-73b5538b92f5 618f7230-6a20-11ea-a18f-d31ef66e5966 b29246d0-6a20-11ea-a18f-d31ef66e5966 c8b85b50-52a8-11ea-af72-73b5538b92f5 702ef8f0-52bb-11ea-af72-73b5538b92f5 4d9b26b0-52c5-11ea-af72-73b5538b92f5 6fbaf910-52c9-11ea-af72-73b5538b92f5 85f93810-52cc-11ea-af72-73b5538b92f5 0cf98080-52ce-11ea-af72-73b5538b92f5 4d3f8640-52d2-11ea-af72-73b5538b92f5 ea9e34b0-6923-11ea-a18f-d31ef66e5966 2b45dd40-693a-11ea-a18f-d31ef66e5966 6f0ed190-6925-11ea-a18f-d31ef66e5966 be870e90-6925-11ea-a18f-d31ef66e5966 01a2dde0-695c-11ea-a18f-d31ef66e5966 19806b70-6953-11ea-a18f-d31ef66e5966 63b89c00-6929-11ea-a18f-d31ef66e5966 817dc600-695d-11ea-a18f-d31ef66e5966 ddd33320-acb7-11ea-a01f-f320212f1d0e 1f04e8b0-accd-11ea-a01f-f320212f1d0e f473cdb0-accb-11ea-a01f-f320212f1d0e 29f5e510-accf-11ea-a01f-f320212f1d0e b53408c0-f1f1-11ea-bb5a-cd2a2f956079 a2cd61d0-f1f2-11ea-bb5a-cd2a2f956079 86988760-5e27-11ea-aafb-371a1379ec5c 32d58f10-5e2c-11ea-aafb-371a1379ec5c 9dba24b0-5e2e-11ea-aafb-371a1379ec5c 50ee61b0-5e3c-11ea-aafb-371a1379ec5c 4377f550-5e6e-11ea-aafb-371a1379ec5c Number-of-Events-Over-Time-By-Event-Log-ecs Number-of-Events-ecs Top-Event-IDs-ecs Event-Levels-ecs Sources-ecs 3bf4ad10-4310-11ea-8d84-3fa749b3b149 57b8b300-52b2-11ea-af72-73b5538b92f5 7b82d7a0-54f3-11ea-af72-73b5538b92f5 32b82b80-54f6-11ea-af72-73b5538b92f5 ba7410e0-54f9-11ea-af72-73b5538b92f5 43b26bf0-55cb-11ea-af72-73b5538b92f5 0a98eb30-56b3-11ea-af72-73b5538b92f5 ab418330-56b8-11ea-af72-73b5538b92f5 37f36380-528f-11ea-af72-73b5538b92f5 60331470-5290-11ea-af72-73b5538b92f5 35ed1880-5319-11ea-af72-73b5538b92f5 7b3262e0-5320-11ea-af72-73b5538b92f5 4398d900-5324-11ea-af72-73b5538b92f5 702ef8f0-52bb-11ea-af72-73b5538b92f5 db32caa0-689b-11ea-a18f-d31ef66e5966 acab19b0-689d-11ea-a18f-d31ef66e5966 2cf94090-68a0-11ea-a18f-d31ef66e5966 134b00c0-68a0-11ea-a18f-d31ef66e5966 ebd181d0-68a5-11ea-a18f-d31ef66e5966 698718f0-68a7-11ea-a18f-d31ef66e5966 9cc05920-68a7-11ea-a18f-d31ef66e5966 faf8a340-68a6-11ea-a18f-d31ef66e5966 8da49440-68a4-11ea-a18f-d31ef66e5966 85c392e0-5e21-11ea-aafb-371a1379ec5c 5df7b130-4f60-11ea-af72-73b5538b92f5 1423b5b0-5274-11ea-af72-73b5538b92f5 a0c83a40-5cc9-11ea-bdfa-cb028c40698b b37b7270-5273-11ea-af72-73b5538b92f5 779d7090-5cc9-11ea-bdfa-cb028c40698b a1ec1640-5cc8-11ea-bdfa-cb028c40698b 740f5d40-5cc8-11ea-bdfa-cb028c40698b)

read -sp "User <$user> will be used to remove 7.9.1 objects from elastic, please enter the password for $user: " -r passwd </dev/tty
echo

for dashboard in "${dashboards[@]}"; do
  curl -sk -XDELETE -s -u "$user":"$passwd" "https://kibana/api/saved_objects/dashboard/${dashboard}" -H 'kbn-xsrf: true'
done

for visual in "${visuals[@]}"; do
  curl -sk -XDELETE -s -u "$user":"$passwd" "https://kibana/api/saved_objects/visualization/${visual}" -H 'kbn-xsrf: true'
done

echo
echo
echo "Removal of 7.9.1 Visuals and Dashboards Complete..."
echo
echo
#################################################################################
#
#			    Unclassified
#
#################################################################################
