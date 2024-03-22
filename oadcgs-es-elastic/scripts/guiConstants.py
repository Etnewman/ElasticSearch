# -*- coding: utf-8 -*-

# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class contains all constants used by the elastic data collector
#          application.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: guiConstants.py
#
# Location: /etc/logstash/scripts
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Mike Kearns, 2021-02-18: Original Version
#
# Site/System: All Sites where Logstash is installed
#
# Deficiency: N/A
#
# Use: This class is part of the elasticDataCollector python application
#      which runs as a service on Logstash VMs
#
# Users: Not for use by users.
#
# DAC Setting: 755 root root
#
# Frequency: N/A
#
# Information Security Authorization
# ACC/A26 IA Approval: year-mm-dd, Name, ACC ISSE
#
# Lead System Engineering Authorization
# AF-DCGS LSE Approval: year-mm-dd, Name, AF-DCGS/AO
#
###########################################################################
DescLabels = {
    "isilon": "----- Isilon -----\n*Please enter the username and password used to access the isilon API \n*URL - Enter the isilon URL | Example: https://10.1.61.201:8080 \n*Display Name - Enter a short name to describe the device | Example: wch-isilon \n*Host - Enter the IP address or a DNS resolvable name for the Isilon",
    "xtremio": "----- Xtremio -----\n*Please enter the username and password used to access the xtremio API \n*URL - Enter the xtremio URL | Example: https://u00av01xms1 \n*Display Name - Enter a short name to describe the device | Example: u00av01xms1 \n*Host - Enter the IP address or a DNS resolvable name for the Xtremio",
    "datadomain": "----- Data Domain -----\n*Please enter the username, password and privPassword used to access the Data Domain \n*URL - Enter the Data Domain URL | Example: https://10.1.60.43 \n*Display Name - Enter a short name to describe the device | Example: ech-datadomain \n*Host - Enter the IP address or a DNS resolvable name for the datadomain",
    "nexus5k": "----- Nexus 5k -----\n*Please enter the username, password and privPassword used to access the Nexus 5k \n*URL - Enter the CISCO Prime URL | Example: https://10.1.60.4 \n*Display Name - Enter a short name to describe the device | Example: ech-nexus5k \n*Host - Enter the IP address or a DNS resolvable name for the Nexus5k",
    "nexus7k": "----- Nexus 7k -----\n*Please enter the username, password and privPassword used to access the Nexus 7k \n*URL - Enter the CISCO Prime URL | Example: https://10.1.61.10 \n*Display Name - Enter a short name to describe the device | Example: ech-nexus7k \n*Host - Enter the IP address or a DNS resolvable name for the Nexus7k",
    "catalyst": "----- Catalyst -----\n*Please enter the username, password and privPassword used to access the Catalyst Switch \n*URL - Enter the CISCO Prime URL | Example: https://10.1.60.8 \n*Display Name - Enter a short name to describe the device | Example: ech-catalyst \n*Host - Enter the IP address or a DNS resolvable name for the Catalyst Switch",
    "fx2": "----- FX2 Chassis -----\n*Please enter the username, password and privPassword used to access the FX2 Chassis \n*URL - Enter the FX2 Chassis URL | Example: https://10.1.60.20 \n*Display Name - Enter a short name to describe the device | Example: ech-fx2 \n*Host - Enter the IP address or a DNS resolvable name for the FX2 Chassis",
    "fc630": "----- FC630 -----\n*Please enter the username, password and privPassword used to access the FC630 \n*URL - Enter the FC630 URL | Example: https://10.1.60.21 \n*Display Name - Enter a short name to describe the device | Example: ech-fc630-2 \n*Host - Enter the IP address or a DNS resolvable name for the FC630",
    "r630": "----- R630 -----\n*Please enter the username, password and privPassword used to access the R630 \n*URL - Enter the FC630 URL | Example: https://10.1.60.25 \n*Display Name - Enter a short name to describe the device | Example: ech-r630-1 \n*Host - Enter the IP address or a DNS resolvable name for the R630",
    "aruba": "----- Aruba -----\n*Please enter the username and password used to access the Aruba API \n*URL - Enter the Aruba URL | Example: https://10.4.0.2.:443 \n*Display Name - Enter a short name to describe the device | Example: wch-aruba \n*Host - Enter the IP address or a DNS resolvable name for the Aruba Switch",
    "hbss_dlp": "----- HBSS DLP -----\n*Please enter the username and password used to access the HBSS DLP API \n*URL - Enter the HBSS URL | Example: https://u00sm01hb00 \n*Display Name - Enter a short name to describe the device | Example: hbss-dlp \n*Host - Enter the IP address or a DNS resolvable name for the HBSS API endpoint",
}
#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
