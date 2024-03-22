# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This is the base class used by all device threads. It provides
#          common methods used by all derived classes.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: Device.py
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
import binascii
import constants
import gzip
import ipaddress
import json
import os
import requests
import threading
import time
import traceback
import shutil
import urllib3
from datetime import datetime
from glob import glob, glob1
from subprocess import check_call
from threading import Thread
from Outfile import Outfile
from Document import Document, DocSubtype
import multiprocessing as mp
from PYSnmpWorker import DeviceData, get_pysnmp

# from SnmpWorker import DeviceData, get_snmp

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


class DeviceType:
    ARUBA = "aruba"
    NEXUS5K = "nexus5k"
    NEXUS7K = "nexus7k"
    CATALYST = "catalyst"
    FX2 = "fx2"
    FC630 = "fc630"
    R630 = "r630"
    ISILON = "isilon"
    XTREMIO = "xtremio"
    DATADOMAIN = "datadomain"
    DLP = "hbss_dlp"

    # Method to return list of all device type available
    @classmethod
    def get_device_types(cls):
        return [value for key, value in vars(cls).items() if key.isupper()]


class Device(Thread):
    # Constructor
    def __init__(self, host, devicetype, hostdesc):
        self.host = host
        self.devicetype = devicetype
        self.hostname = hostdesc
        self.snmp_session = 0
        self.rest_session = 0
        self.dowork = True
        Thread.__init__(self)

        self.snmpsetup = False
        self.restsetup = False
        self.lock = threading.Lock()
        self.outfile = Outfile(constants.DEVICE_OUTPUTDIR, self.devicetype)

        self.snmp_timeout = constants.DEVICE_SNMPTMOUT

    def setup_snmp(self, user, authPass, privPass, timeout=500000):
        self.snmp_user = user
        self.snmp_authPass = authPass
        self.snmp_privPass = privPass
        self.snmpsetup = True
        self.snmp_timeout = timeout

    def setup_rest(self, user, passwd, port):
        self.rest_user = user
        self.rest_passwd = passwd
        self.rest_port = port
        self.restsetup = True

    def isIP(self, string):
        try:
            ipaddress.ip_address(str(string))
            return True
        except:
            return False

    def DeviceDoc(self, docType):
        return Document(docType, DocSubtype.DEVICE, self.devicetype, self.hostname)

    #
    # Method: test_access - this method is used to test access to
    # an device that is being monitored via snmp.  If the device
    # is using rest this method should be overridden. This method
    # will automatically return False if the device is not using
    # snmp
    #
    # Parameters:
    #   None
    # Returns:
    #   None
    def test_access(self):
        retval = False

        if self.snmpsetup:
            # Use System Uptime OID for testing
            # OID = 1.3.6.1.2.1.1.3.0
            rsp = self.get_pysnmpdata("SNMPv2-MIB", "sysUpTime")
            if rsp.error == 0:
                retval = True

        return retval

    # Method: get_pysnmpdata - Used to get data from device using pysnmp
    # Parameters:
    #    mib -
    #    group -
    # Returns:
    #   - DeviceData object containing query results
    #
    def get_pysnmpdata(self, mib, group):
        retval = DeviceData()  # Initialize to empty incase of failure
        if self.snmpsetup:
            parent_conn, child_conn = mp.Pipe()
            worker = mp.Process(
                target=get_pysnmp,
                args=(
                    mib,
                    group,
                    self.host,
                    self.snmp_user,
                    self.snmp_authPass,
                    self.snmp_privPass,
                    child_conn,
                ),
            )
            worker.name = "PYSNMPWorker-" + self.hostname
            worker.start()

            retval = parent_conn.recv()
            worker.join(5)
            if worker.exitcode == None:
                worker.terminate()

            # for var in  retval.value:
            #   print( 'mib:', var.mib, "tag:", var.tag, "iid:", var.iid, "val:", var.val)
            if retval.error != 0:
                print("Device: Error in get_pysnmp: ", retval.errorStr)

        return retval

    # Method: get_snmpdata - Used to get data from device
    # Parameters:
    #    oid - Object Identifier for SNMP walk on device
    # Returns:
    #   - DeviceData object containing query results
    #
    # Comment out unused function so import of netsnmp is not needed
    #    def get_snmpdata(self, oid):
    #        retval = DeviceData()  # Initialize to empty incase of failure
    #        if self.snmpsetup:
    #            # Spawn SnmpWorker to handle request
    #            parent_conn, child_conn = mp.Pipe()
    #            worker = mp.Process(
    #                target=get_snmp,
    #                args=(
    #                    oid,
    #                    self.host,
    #                    self.snmp_user,
    #                    self.snmp_authPass,
    #                    self.snmp_privPass,
    #                    child_conn,
    #                ),
    #            )
    #            worker.name = "SNMPWorker-" + self.hostname
    #            worker.start()
    #
    #            retval = parent_conn.recv()
    #            worker.join()
    #
    #            # for var in  self.devdata.value:
    #            #  print( 'tag:',var.tag, "iid:", var.iid, 'type:(', var.type,')', "val:", var.val)
    #        return retval

    # Method: _restSession - Private method to create a requests Session
    # Parameters:
    #    None
    # Returns:
    #   None - sets class variable rest_session
    def _restSession(self):
        self.rest_session = requests.Session()
        self.rest_session.verify = False

        if self.devicetype == DeviceType.ARUBA:
            self.rest_session.headers.update({"Accept": "*/*"})
            requrl = (
                "https://"
                + self.host
                + ":"
                + str(self.rest_port)
                + "/"
                + "rest/v10.12/login"
            )
            data = {"username": self.rest_user, "password": self.rest_passwd}
            # print("requrl:", requrl)
            # print("data:", data)
            try:
                r = self.rest_session.post(requrl, data=data)
                if not r.ok:
                    print(
                        f"Aruba Connection Error\nHTTP Code: {r.status_code} \n  Reason: {r.reason} \n Message: {r.text}"
                    )
            except Exception as ex:
                print(
                    "Exception:",
                    type(ex).__name__,
                    " on device:",
                    self.hostname,
                    " for url:",
                    requrl,
                )
                self.rest_session = 0
        else:
            self.rest_session.auth = (self.rest_user, self.rest_passwd)

    # Method: get_restdata - Used to get data from device
    # Parameters:
    #    oid - Object Identifier for SNMP walk on device
    # Returns:
    #   - result of rest request
    #   - query_time - Time of query (Right after)
    def get_restdata(self, url):
        retval = DeviceData()
        retval.error = -1

        if self.rest_session == 0:
            self._restSession()

        if self.rest_session != 0:
            requrl = "https://" + self.host + ":" + str(self.rest_port) + "/" + url
            try:
                retval.query_time = time.time()
                r = self.rest_session.get(requrl, timeout=60)

                if r.status_code == 200 or r.status_code == 207:
                    retval.error = 0
                    retval.value = r.json()
                else:
                    print(f"get_restdata failed with status code:{r.status_code}")
            except Exception as ex:
                print(
                    "Exception:",
                    type(ex).__name__,
                    " on device:",
                    self.hostname,
                    " for url:",
                    url,
                )

        return retval

    # Method: output - method used to write data to file. Data is
    #                  passed to OutFile Object
    # Parameters:
    #   item - item to be written, can be attribute or dictionary
    #   outfile - file object to write data to
    # Returns:
    #   None
    def output(self, item):
        self.outfile.output(item)

    # Method: run - baseclass run method for Thread.  This method should
    #               be overriden
    # Parameters:
    #   None
    # Returns:
    #   None
    def run(self):
        try:
            self.setName(self.hostname)
            self.work()
        except:
            traceback.print_exc()
        # print "exiting thread"


#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
