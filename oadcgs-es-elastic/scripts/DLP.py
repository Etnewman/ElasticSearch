# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class used to query data from FX2 blade servers.  It
#          derives from the Device class and runs in it's own thread to
#          query health and status information from the blade servers.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: DLP.py
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
# Use: This class is part of the elasticDataCollector python application
#      which runs as a service on Logstash VMs
#
# Users: Not for use by users.
#
# DAC Setting: 755 root root
#
# Frequency: Runs as a thread in the elasticDataCollector Service
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
import logging
import constants
import json
import time
from Device import Device, DeviceType
from Document import DocType, Health
from DeviceInfo import DeviceInfo, SNMPDeviceInfo
import os.path
import datetime
import threading


class DLP(Device):
    def __init__(self, devinfo):
        Device.__init__(self, devinfo.host, devinfo.devicetype, devinfo.hostname)

        self.setup_rest(devinfo.user, devinfo.passwd, devinfo.port)
        self.last_eventquery_file = constants.DLP_LAST_EVENT_QUERY
        self.url = devinfo.url

    def __get_time_from_file(self, filename):
        if os.path.isfile(filename):
            f = open(filename, "r")
            timeval = f.read()
        else:
            # if not query time get about 1 years worth
            timeval = str(int((time.time() * 1000) - 31536000000))

        return timeval

    def __save_time_to_file(self, filename):
        f = open(filename, "w")
        f.write(str(int(time.time() * 1000)))
        f.close

    def test_access(self):
        retval = False
        result = self.get_restdata("rest/dlp/incidents/customAttribute/list")
        if result.error == 0:
            retval = True
        else:
            print(f"testaccess return code:{result.error}")

        return retval

    def get_incidentlist(self):

        querytime = self.__get_time_from_file(self.last_eventquery_file)
        result = self.get_restdata(
            f"rest/dlp/incidents/ids?startTime={querytime}&incidentNature=1"
        )

        if (
            result.error == 0 and "incidentIds" in result.value.keys()
        ):  # Verify that incidentIds key exists
            self.__save_time_to_file(self.last_eventquery_file)
            incidentIds = result.value["incidentIds"]
            for incidentId in incidentIds:
                incident = self.get_restdata(
                    f"rest/dlp/incidents/{incidentId}?incidentNature=1"
                )

                incidentDoc = self.DeviceDoc(DocType.STATUS)
                incidentDoc.add_description("DLP Incident information")
                for item in incident.value:
                    incidentDoc.set_value(item, incident.value[item])

                self.output(incidentDoc)

    #
    # Method: work - work
    #
    def work(self):
        while self.dowork:
            self.get_incidentlist()
            time.sleep(constants.DLP_SLEEP)


#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
