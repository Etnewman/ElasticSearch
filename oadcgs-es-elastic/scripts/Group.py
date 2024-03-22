# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class is used to hold information about a Group of hosts
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: Group.py
#
# Location: /etc/logstash/scripts
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Steve Truxal, 2021-08-04: Original Version
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
# Frequency: Group Objects are added to application dictionary
#
# Information Security Authorization
# ACC/A26 IA Grouproval: year-mm-dd, Name, ACC ISSE
#
# Lead System Engineering Authorization
# AF-DCGS LSE Grouproval: year-mm-dd, Name, AF-DCGS/AO
#
###########################################################################
#
import threading
import time
from datetime import datetime
from Document import Document, DocType, Health, DocSubtype


class Group:
    stale_threshold = 300

    # Constructor
    def __init__(self, name, groupHosts, minHosts, hostdic):
        self.hosts = hostdic
        self.groupName = name
        self.Grouplock = threading.Lock()
        self.groupHosts = groupHosts
        self.minHosts = int(minHosts)
        self.lastupdate = 0
        self.health = Document(DocType.HEALTH, DocSubtype.GROUP, None, name)

        # Add required hosts to document
        self.health.set_value("group.hosts", groupHosts)
        self.health.set_value("group.minHosts", minHosts)

    def print_hosts(self):
        for host in self.groupHosts:
            print("host:", host, " Status:", self.hosts[host]["Status"])

    def get_health(self):
        self.Grouplock.acquire()
        groupStatus = Health.OK
        self.health.clear_health_symptoms()
        timeThreshold = time.time() - Group.stale_threshold
        for host in self.groupHosts:
            if host in self.hosts.keys():
                hhealth = self.hosts[host].get_health()
                if hhealth != Health.OK:
                    self.health.add_health_symptom(host + ":" + hhealth)
            else:
                self.health.add_health_symptom(host + ": Missing Data")

        badhosts = len(self.health.get_health_symptoms())
        upcount = len(self.groupHosts) - badhosts
        if upcount < self.minHosts:
            groupStatus = Health.DOWN

        if badhosts == 0:
            self.health.add_health_symptom("none")

        self.health.set_health(groupStatus)
        # Python3 version
        # self.health.set_value("@timestamp", datetime.utcnow().isoformat(sep='T', timespec='milliseconds')+'Z')
        self.health.set_value("@timestamp", datetime.utcnow().isoformat(sep="T") + "Z")
        self.Grouplock.release()
        return groupStatus

    def get_healthdoc(self):
        self.get_health()
        return self.health


#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
