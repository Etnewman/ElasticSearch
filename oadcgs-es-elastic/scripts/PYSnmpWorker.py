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
import os
import threading
import time
import traceback
from multiprocessing import Process, Pipe, current_process
import constants
import setproctitle
from pysnmp.smi import builder, compiler
from pysmi.compiler import MibCompiler
from pysnmp.hlapi import *
from pysnmp.entity.rfc3413 import context
from pysnmp import debug
from pysnmp.smi import compiler, view, rfc1902
from pysnmp.hlapi import varbinds


class DeviceData:
    def __init__(self):
        self.query_time = 0
        self.error = 0
        self.errorStr = "Uninitialized"
        self.value = []


class DevEntry:
    def __init__(self):
        self.mib = None
        self.tag = None
        self.iid = None
        self.val = None


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
def get_pysnmp(mib, group, host, snmp_user, snmp_authPass, snmp_privPass, pipe):

    setproctitle.setproctitle(current_process().name)
    devdata = DeviceData()

    auth = UsmUserData(
        snmp_user,
        authKey=snmp_authPass,
        privKey=snmp_privPass,
        authProtocol=usmHMACSHAAuthProtocol,
        privProtocol=usmAesCfb128Protocol,
    )

    snmp_engine = SnmpEngine()
    snmp_context = context.SnmpContext(snmp_engine)
    devdata.errorStr = "Host:" + host + " Mib:" + mib + " Group: " + group

    try:

        for (errorIndication, errorStatus, errorIndex, varBinds) in nextCmd(
            SnmpEngine(),
            auth,
            UdpTransportTarget(
                (host, 161), timeout=constants.DEVICE_PYSNMPTMOUT, retries=1
            ),
            ContextData(),
            ObjectType(
                ObjectIdentity(mib, group).addMibSource(constants.SCRIPTS_DIR + "MIBS")
            ),
            lexicographicMode=False,
            lookupMib=True,
        ):

            #        print("varbinds len=", len(varBinds))
            if errorIndication:
                print(
                    "Mib:",
                    mib,
                    " Group: ",
                    group,
                    " Error:",
                    devdata.error,
                    " ErrorIndication:",
                    errorIndication,
                )
                devdata.errorStr = devdata.errorStr + " Error:" + str(errorIndication)
                devdata.error = -1
                break
            elif errorStatus:
                print(
                    "%s at %s"
                    % (
                        errorStatus.prettyPrint(),
                        errorIndex and varBinds[int(errorIndex) - 1][0] or "?",
                    )
                )
                devdata.errorStr = (
                    devdata.errorStr
                    + " Error:"
                    + str(errorStatus)
                    + str(varBinds[int(errorIndex) - 1][0])
                )
                devdata.error = -1
                break
            else:
                # print("Good Data:", " Mib:",mib, " Group: ", group)
                devdata.error = 0
                devdata.query_time = time.time()
                for varBind in varBinds:
                    v = str(varBind)
                    devent = DevEntry()
                    devent.mib = v.split("::")[0]
                    devent.tag = v.split("::")[1].split(".")[0]
                    devent.iid = v.split(".", 1)[1].split("=")[0].strip()
                    devent.val = v.split("=")[1].strip()
                    devdata.value.append(devent)

    except Exception as e:
        print("Error in get_pysnmp for host: ", host, " error=", devdata.error)
        print("Exception:", str(e))
        print("errorStr:", devdata.errorStr)
        devdata.errorStr = str(e)
        devdata.error = -1

    pipe.send(devdata)
    pipe.close()

    return


#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
