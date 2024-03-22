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
# File name: constants.py
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
#
# Define Scripts directory
SCRIPTS_DIR = "/etc/logstash/scripts/"

# Define data/working directory
DATA_DIR = SCRIPTS_DIR + "data/"

# sysconfig filepath for logstash
SYSCONFIG_FILE = "/etc/sysconfig/logstash"

# Main Constants
# Location of the devices json configuration file
MAIN_DEVICE_CONF = DATA_DIR + "deviceconfig.json"

# Application and Groups config file
APPS_CONF = "/ELK-local/elasticDataCollector/appsconfig.ini"
GRPS_CONF = "/ELK-local/elasticDataCollector/groups.ini"

# Querier data file for elastic authentication
QUERIER_DAT = DATA_DIR + "querier.dat"

# Vsphere data file for service account authentication
VSPHERE_DAT = DATA_DIR + "vsphere.dat"

# Data file with location of Elastic Cluster
CLUSTER_SITES = DATA_DIR + "clusterSites.dat"

CLUSTER_OUTPUTS = DATA_DIR + "clusterOutputs.dat"

# Node number for ElasticConnection.py
ELASTIC_CON_NODE = "1"

# Data file to keep track of where Watcher is in host file for retarts
WATCHER_FILE_POS = DATA_DIR + "watcher.last_pos"

# Data file to keep track of last event query time from XtremIO
XTREMIO_LAST_EVENT_QUERY = DATA_DIR + "xtremio.last_event_querytime"

# Data file to keep track of last event query time from Vsphere API
VSPHERE_LAST_EVENT_QUERY = DATA_DIR + "vsphere.last_event_querytime"

# Aruba Class Constants
# Data file to keep track of last event query time from DLP API
DLP_LAST_EVENT_QUERY = DATA_DIR + "hbssdlp.last_event_querytime"

# DLP_SLEEP is the number of seconds between queries for DLP events
DLP_SLEEP = 300

# Device Class Constants
# DEVICE_BKPS is the number of backup rotations to keep
DEVICE_BKPS = 3

# DEVICE_BKPS_SIZE is the size of backups in bytes before rotation
# 100000000=100M
DEVICE_BKPS_SIZE = 100000000

# DEVICE_OUTPUTDIR is the output directory to store the device json files
# before logstash gathers them to transfer to elasticsearch
DEVICE_OUTPUTDIR = "/ELK-local/device_data"

# HealthData Metrics output directory
HEALTH_METRICS_OUT = "/ELK-local/metrics_out"

# HealthData Metrics input directory (metrics written by Logstash)
HEALTH_METRICS_IN = "/ELK-local/metrics_in"

# DEVICE_MIBSDIR is the location of the MIB files used to translate
# snmp calls from OIDs to meaningful text
DEVICE_MIBSDIR = "+/etc/logstash/MIBS"

# DEVICE_MIBS load ALL MIB files in DEVICE_MIBSDIR instead of specifying
# individual files
DEVICE_MIBS = "ALL"

# DEVICE_SNMPTMOUT is the timeout in microseconds to wait for a snmp
# call to finish. 5000000 microseconds = 5 second
DEVICE_SNMPTMOUT = 5000000

# DEVICE_PYSNMPTMOUT is the timeout in seconds to wait for a pysnmp
# call to finish.
DEVICE_PYSNMPTMOUT = 60

# DataDomain Class Constants
# DATADOMAIN_SLEEP is the number of seconds between executions
DATADOMAIN_SLEEP = 60

# DATADOMAIN_DOWNTIME is the threshold for system availability
# anything less than 0.95=95% reported
DATADOMAIN_DOWNTIME = 0.95

# Xtremio Class Constants
# XTREMIO_SLEEP is the number of seconds between executions
XTREMEIO_SLEEP = 60

# CiscoSwitch Class Constants
# CISCOSWITCH_SLEEP is the number of seconds between executions
CISCOSWITCH_SLEEP = 60

# CISCOSWITCH_UTILIZATION is the maximum utilization 0.95=95%
# anything greater than 0.95=95% reported
CISCOSWITCH_UTILIZATION = 0.95

# CISCOSWITCH_CPUAVE#KTEMP is the average temperature in Celsius
CISCOSWITCH_CPUAVE3KTEMP = 46.0
CISCOSWITCH_CPUAVE5KTEMP = 54.0
CISCOSWITCH_CPUAVE7KTEMP = 31.0

# CISCOSWITCH_INLETAVE#KTEMP is the average temperature in Celsius
CISCOSWITCH_INLETAVE3KTEMP = 32.0
CISCOSWITCH_INLETAVE5KTEMP = 28.0
CISCOSWITCH_INLETAVE7KTEMP = 20.0

# CISCOSWITCH_ CPUMAJOR_#KTEMP is the average temperature in Celsius
CISCOSWITCH_CPUMAJOR_3KTEMP = 125.0
CISCOSWITCH_CPUMAJOR_5KTEMP = 125.0
CISCOSWITCH_CPUMAJOR_7KTEMP = 85.0

# CISCOSWITCH_ CPUMINOR_#KTEMP is the average temperature in Celsius
CISCOSWITCH_CPUMINOR_3KTEMP = 105.0
CISCOSWITCH_CPUMINOR_5KTEMP = 110.0
CISCOSWITCH_CPUMINOR_7KTEMP = 75.0

# CISCOSWITCH_ INLETMAJOR_#KTEMP is the average temperature in Celsius
CISCOSWITCH_INLETMAJOR_3KTEMP = 56.0
CISCOSWITCH_INLETMAJOR_5KTEMP = 110.0
CISCOSWITCH_INLETMAJOR_7KTEMP = 60.0

# CISCOSWITCH_ INLETMINOR_#KTEMP is the average temperature in Celsius
CISCOSWITCH_INLETMINOR_3KTEMP = 46.0
CISCOSWITCH_INLETMINOR_5KTEMP = 100.0
CISCOSWITCH_INLETMINOR_7KTEMP = 42.0

# Isilon Class Constants
# ISILON_SLEEP is the number of seconds between executions
ISILON_SLEEP = 60

# DellIdrac Class Constants
# DELLIDRAC_SLEEP is the number of seconds between executions
DELLIDRAC_SLEEP = 60

# Fx2 Class Constants
# FX2_SLEEP is the number of seconds between executions
FX2_SLEEP = 60

# ACAS Class Constants
# ACAS_SLEEP is the number of seconds between executions
# ACAS_ON is a boolean for whether we want ACAS activated or not
# ACAS_DAT is the directory for acas.dat
ACAS_SLEEP = 86400
ACAS_ON = False
ACAS_DAT = DATA_DIR + "acas.dat"

# Stale Cleanup Class Constants
# Elastic Query to get docs older than 7 days
# ELAC_UPTIME is a number in seconds of how long the data collecotr has to be up for
STALE_QUERY_TIME = "now-7d"
STALE_ELAC_UPTIME = 600

# Data Collector API Constants
DATACOLLECTOR_API_HOST = "localhost"
DATACOLLECTOR_API_PORT = 9601

# Data Collector Maximum Thread Restart Attempts constants
MAX_RESTARTS = 5
# Data collector restart time threshold (in minutes)
RESTART_TIME_THRESHOLD = 15

# Time primary cluster should be unreachable before switching to secondary cluster (in minutes)
DISCONNECT_THRESHOLD = 15

# AUDITS
# AUDITS_QUERY_TIME is the time the query looks back for audit hosts(24hrs ago)
AUDITS_QUERY_TIME = "now-24h"

#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
