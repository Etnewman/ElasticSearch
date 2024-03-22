# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This is a worker function to preform SNMP requests to devices.
#          This function is sub-processed by the Device class for all
#          snmp requests.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: SnmpWorker.py
#
# Location: /etc/logstash/scripts
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Steve Truxal, 2021-01-08: Original Version
#
# Site/System: All Sites where Logstash is installed
#
# Deficiency: N/A
#
# Use: This class part of the elasticDataCollector python application
#      which runs as a service on Logstash VMs
#
# Users: Not for use by users.
#
# DAC Setting: 755 root root
#
# Frequency: Base class inherited by all device classes
#
# Information Security Authorization
# ACC/A26 IA Approval: year-mm-dd, Name, ACC ISSE
#
# Lead System Engineering Authorization
# AF-DCGS LSE Approval: year-mm-dd, Name, AF-DCGS/AO
#
###########################################################################
#
import netsnmp
import os
import threading
import time
import traceback
from multiprocessing import Process, Pipe, current_process
import constants
import setproctitle


class DeviceData:
    def __init__(self):
        self.query_time = 0
        self.error = -1
        self.errorStr = "Uninitialized"
        self.value = None


# Specify environment variables for netsnmp. All of our MIBS should be in the directory named below.
os.environ["MIBS"] = constants.DEVICE_MIBS
os.environ["MIBDIRS"] = constants.DEVICE_MIBSDIR


# Method: get_snmp - Used to get data from device
# Parameters:
#    oid - Object Identifier for SNMP walk on device
#    host - Host to do snmp request on (normally IP Address)
#    snmp_user - User to make snmp request with
#    snmp_authPass - SNMP Authentication password
#    snmp_privPass - SNMP Privacy password
#    pipe - Pipe to pass data back to elasticDataCollector
#
# Returns:
#   - devdata - DeviceData object with results from snmp query
#
def get_snmp(oid, host, snmp_user, snmp_authPass, snmp_privPass, pipe):

    setproctitle.setproctitle(current_process().name)
    devdata = DeviceData()

    try:
        snmp_session = netsnmp.Session(
            DestHost=host,
            Version=3,
            SecLevel="authPriv",
            AuthProto="SHA",
            AuthPass=snmp_authPass,
            PrivProto="AES",
            PrivPass=snmp_privPass,
            SecName=snmp_user,
            Timeout=constants.DEVICE_SNMPTMOUT,
        )
        snmp_session.UseEnums = 1
    except:
        print("Unable to setup session for host: ", host)
        snmp_session = None

    if snmp_session is not None:
        oid_obj = netsnmp.VarList(netsnmp.Varbind(oid))
        try:
            value_obj = snmp_session.walk(oid_obj)
            devdata.query_time = time.time()
            devdata.value = oid_obj
            devdata.error = snmp_session.ErrorInd
            devdata.errorStr = snmp_session.ErrorStr
            # print("Host:", hostname, "Walk Error status: ErrorStr:",  snmp_session.ErrorStr, "ErrorNum:", snmp_session.ErrorNum, "ErrInd:",snmp_session.ErrorInd)

        except:
            print(
                "Excepton on get_snmpdata returned, host: ", host, " oid : ", oid,
            )
            devdata.error = -1

        pipe.send(devdata)
        pipe.close()

    return


#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
