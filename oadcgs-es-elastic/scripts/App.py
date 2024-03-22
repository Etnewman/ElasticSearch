# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class is used to hold information about and application
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: App.py
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
# Frequency: App Objects are added to application dictionary
#
# Information Security Authorization
# ACC/A26 IA Approval: year-mm-dd, Name, ACC ISSE
#
# Lead System Engineering Authorization
# AF-DCGS LSE Approval: year-mm-dd, Name, AF-DCGS/AO
#
###########################################################################
#
import threading
import time
from datetime import datetime
from Document import Document, DocType, Health, DocSubtype


class App:
    stale_threshold = 300

    # Constructor
    def __init__(self, name, requiredHosts):
        self.AppName = name
        self.Applock = threading.Lock()
        self.requiredHosts = requiredHosts
        self.hostlist = {}
        self.lastupdate = 0
        self.health = Document(DocType.HEALTH, DocSubtype.APP, None, name)
        # Add required hosts to document
        reqs = []
        for item in requiredHosts:
            reqs.append(item + ":effect(" + requiredHosts[item]["effect"] + ")")
        self.health.add_app_hosts(reqs)

    def update_app(self, host, appInfo, updatetime):
        # Only update host if it's part of defined application from ini config
        if host in self.requiredHosts.keys():
            self.Applock.acquire()
            self.hostlist[host] = appInfo
            self.requiredHosts[host]["lastupdate"] = updatetime
            self.Applock.release()

    def print_hosts(self):
        for host in self.hostlist:
            print("host:", host, " Status:", self.hostlist[host]["Status"])

    def get_health(self):
        self.Applock.acquire()
        appStatus = Health.OK
        self.health.clear_health_symptoms()
        timeThreshold = time.time() - App.stale_threshold
        for host in self.requiredHosts:
            # print ("host:", host, " timeThreshold:", timeThreshold, " lastupdate:", self.requiredHosts[host]["lastupdate"])
            if (
                host in self.hostlist.keys()
                and self.requiredHosts[host]["lastupdate"] > timeThreshold
            ):
                if self.hostlist[host]["Status"] != Health.OK:
                    self.health.add_health_symptom(
                        host + ":" + self.hostlist[host]["Status"]
                    )
                    if appStatus != Health.DOWN:
                        if (
                            self.requiredHosts[host]["effect"] == Health.DOWN
                            and self.hostlist[host]["Status"] == Health.DOWN
                        ):
                            appStatus = Health.DOWN
                        else:
                            appStatus = Health.DEGRADED
            else:
                self.health.add_health_symptom(host + ": Missing Data")
                if (
                    self.requiredHosts[host]["effect"] != Health.DOWN
                    and appStatus != Health.UNKNOWN
                ):
                    appStatus = self.requiredHosts[host]["effect"]
                else:
                    appStatus = Health.UNKNOWN

        if len(self.health.get_health_symptoms()) == 0:
            self.health.add_health_symptom("none")

        self.health.set_health(appStatus)
        # Python3 version
        # self.health.set_value("@timestamp", datetime.utcnow().isoformat(sep='T', timespec='milliseconds')+'Z')
        self.health.set_value("@timestamp", datetime.utcnow().isoformat(sep="T") + "Z")
        self.Applock.release()
        return appStatus

    def get_healthdoc(self):
        self.get_health()
        return self.health


#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
