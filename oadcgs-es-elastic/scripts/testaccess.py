# -*- coding: utf-8 -*-
#
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This script is used to verify access to the configured devices.
#          It is used by they configurator GUI to ensure the installer
#          enters the correct information to allow device access.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: testaccess.py
#
# Location: /etc/logstash/scripts
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Steve Truxal, 2021-03-08: Original Version
#
# Site/System: All Sites where Logstash is installed
#
# Deficiency: N/A
#
# Use: This script is part of the elasticDataCollector python application
#      which runs as a service on Logstash VMs
#
# Users: Not for use by users.
#
# DAC Setting: 755 root root
#
# Frequency: Called from configurator script
#
# Information Security Authorization
# ACC/A26 IA Approval: year-mm-dd, Name, ACC ISSE
#
# Lead System Engineering Authorization
# AF-DCGS LSE Approval: year-mm-dd, Name, AF-DCGS/AO
#
###########################################################################
#
from DeviceInfo import DeviceInfo, SNMPDeviceInfo, Devices
from Device import DeviceType
from Isilon import Isilon
from Xtremio import Xtremio
from CiscoSwitch import CiscoSwitch
from DataDomain import DataDomain
from DellIdrac import DellIdrac
from Fx2 import Fx2
import sys
import json
import threading
import time


def main():

    ret_list = list()
    output_list = list()
    with open(("/tmp/testconfig.json"), "r") as devicefile:
        config = json.load(devicefile)

    devicelist = list()
    for device in config["devices"]:
        mydev = DeviceInfo()
        mydev.loadjson(json.dumps(device))

        if device["devicetype"] == DeviceType.ISILON:
            devicelist.append(Isilon(mydev))
        elif device["devicetype"] == DeviceType.XTREMIO:
            devicelist.append(Xtremio(mydev))
        elif (
            device["devicetype"] == DeviceType.NEXUS5K
            or device["devicetype"] == DeviceType.NEXUS7K
            or device["devicetype"] == DeviceType.CATALYST
        ):
            devicelist.append(CiscoSwitch(mydev))
        elif device["devicetype"] == DeviceType.FX2:
            devicelist.append(Fx2(mydev))
        elif device["devicetype"] == DeviceType.DATADOMAIN:
            devicelist.append(DataDomain(mydev))
        elif (
            device["devicetype"] == DeviceType.FC630
            or device["devicetype"] == DeviceType.R630
        ):
            devicelist.append(DellIdrac(mydev))

        # print(json.dumps(mydev, default=lambda o:o.__dict__, indent=4))

    for dev in devicelist:
        res = dev.test_access()
        print("Thread name", dev.hostname, "Access:", res, "\n")
        res2 = str(res)
        output = dev.hostname, "Access:", res2
        hostname = str(dev.hostname)
        result = str(res)
        ret_list.append(hostname)
        ret_list.append(result)
        output_list.append(output)

    return ret_list, output_list


if __name__ == "__main__":
    main()
#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
