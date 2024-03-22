# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class is utility class to load/setup Device information.
#          After created the instantiated object is passed to device
#          classes in their constructors. The class is also used during
#          device access verification.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: DeviceInfo.py
#
# Location: /etc/logstash/scripts
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Steve Truxal, 2021-01-18: Original Version
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
# Frequency: Passed as paramter to device class constructors
#
# Information Security Authorization
# ACC/A26 IA Approval: year-mm-dd, Name, ACC ISSE
#
# Lead System Engineering Authorization
# AF-DCGS LSE Approval: year-mm-dd, Name, AF-DCGS/AO
#
###########################################################################
#
import json
import sys
from Device import DeviceType
from Crypt import Crypt


class DeviceInfo(object):
    def loadjson(self, j):
        self.__dict__ = json.loads(j)
        self.passwd = Crypt().decode(str(self.passwd))
        if hasattr(self, "privPass"):
            self.privPass = Crypt().decode(str(self.privPass))

    # Method used for testing
    def setup(
        self, host, port, devicetype, user, passwd, hostdesc, url, timeout=500000
    ):
        self.host = host
        self.port = port
        self.devicetype = devicetype
        self.user = user
        # self.passwd = Crypt().encode(passwd)
        self.passwd = passwd
        self.hostname = hostdesc
        self.url = url
        self.timeout = timeout

        # print ("Host=", self.host)

    # Method used for testing
    def setupSNMP(
        self, host, devicetype, user, authPass, privPass, hostdesc, url, timeout=500000
    ):
        self.setup(host, 161, devicetype, user, authPass, hostdesc, url, timeout)
        # self.privPass = Crypt().encode(privPass)
        self.privPass = privPass


class SNMPDeviceInfo(DeviceInfo):
    def loadjson(self, j):
        self.__dict__ = json.loads(j)
        self.privPass = Crypt().decode(str(self.PrivPass))

    # Method used for testing
    def setup(
        self, host, devicetype, user, authPass, privPass, hostdesc, url, timeout=500000
    ):
        DeviceInfo.setup(
            self, host, 161, devicetype, user, authPass, hostdesc, url, timeout
        )

        # self.privPass = privPass
        # self.privPass = Crypt().encode(privPass)
        self.privPass = privPass


class Devices:
    def __init__(self):
        self.devices = list()

    def add_device(self, device):
        print("adding:", json.dumps(device, default=lambda o: o.__dict__, indent=4))
        self.devices.append(device)


#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
