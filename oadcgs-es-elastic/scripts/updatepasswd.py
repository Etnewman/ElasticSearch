# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This is a utility script used to create the encrypted password
#          file used for vsphere access.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: updatepasswd.py
#
# Location: /etc/logstash/scripts
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Steve Truxal, 2022-01-06: Original Version
#
# Site/System: All Sites where Logstash is installed
#
# Deficiency: N/A
#
# Use: This script is a utility script used during installation
#
# Users: Not for use by users.
#
# DAC Setting: 755 root root
#
# Frequency: runs as a thread in the elasticDataCollector app
#
# Information Security Authorization
# ACC/A26 IA Approval: year-mm-dd, Name, ACC ISSE
#
# Lead System Engineering Authorization
# AF-DCGS LSE Approval: year-mm-dd, Name, AF-DCGS/AO
#
###########################################################################
#
import socket
import getpass
import constants
from Crypt import Crypt

svcacct = socket.getfqdn(socket.gethostname()[1:3] + "_elastic.svc")
querystr = "Enter " + svcacct + " password:"
querystr1 = "Re-enter " + svcacct + " password:"

print
while True:
    try:
        p1 = getpass.getpass("\nEnter %s service account password:" % svcacct)
    except Exception as error:
        print("Error", error)

    try:
        p2 = getpass.getpass("\nRe-enter %s service account password:" % svcacct)
    except Exception as error:
        print("Error", error)

    if p1 == p2:
        break
    else:
        print("\nPasswords don't match, try again.\n")


with open(constants.VSPHERE_DAT, "w+") as outfile:
    outfile.write(svcacct + ":" + Crypt().encode(p1))

print("\n" + svcacct + " password updated...\n\n")
