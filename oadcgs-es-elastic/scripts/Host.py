# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class holds health information about a host.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: Host.py
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
# Frequency: App Objects are added to host dictionary
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
from time import strptime
from Document import Document, DocType, Health, DocSubtype, Symptom
import json


class Host:
    stale_threshold = 300

    # Constructor
    def __init__(self, hostname, hostinfo=None):
        self.hostlock = threading.Lock()
        self.hostname = hostname
        self.lastupdate = 0
        self.audits = "Initializing"
        self.health = Document(DocType.HEALTH, DocSubtype.HOST, None, self.hostname)
        if hostinfo is not None:
            self.update_host(hostinfo)

    def update_host(self, hostinfo):
        self.hostlock.acquire()
        self.health.loadjson(json.dumps(hostinfo))
        ts = self.health.get_value("@timestamp")
        tmptime = strptime(ts, "%Y-%m-%dT%H:%M:%S.%fZ")
        self.lastupdate = time.mktime(tmptime)
        self.__add_audits_to_document()
        self.hostlock.release()

    def get_lastupdate_time(self):
        return self.lastupdate

    #
    # pingstatus = up/down
    # Returns True if health is stale and false if not
    def update_health(self, pingstatus):
        # Check to see if health is stale, if it is then
        # We need to make a new document based on the pingstatus
        self.hostlock.acquire()
        if (time.time() - Host.stale_threshold) > self.lastupdate:
            # print("Host Health is STALE -- lastupdate:", self.lastupdate, " Host=", self.hostname)
            retval = True
            # If Doc is stale then update with other info
            self.health = Document(DocType.HEALTH, DocSubtype.HOST, None, self.hostname)
            self.health.add_subtype("host")
            self.health.add_health_symptom("No_Metrics")
            self.health.set_value("monitor.status", pingstatus)
            self.health.set_value(
                "@timestamp", datetime.utcnow().isoformat(sep="T") + "Z"
            )
            self.__add_audits_to_document()
            if pingstatus == "up":
                self.health.set_health(Health.UNKNOWN)
            else:
                self.health.add_health_symptom("No_Ping")
                self.health.set_health(Health.DOWN)
        else:
            # Health is not stale so just add pingstatus
            self.health.set_value("monitor.status", pingstatus)
            retval = False

        self.hostlock.release()

        return retval

    def get_health(self):
        return self.health.get_health()

    def get_healthdoc(self):
        return self.health

    def get_symptom(self):
        self.hostlock.acquire()
        try:
            tmpval = self.health.get_health_symptoms()
        except:
            tmpval = "UNKNOWN"
        self.hostlock.release()
        return tmpval

    def get_hostname(self):
        self.hostlock.acquire()
        tmpval = self.health.get_hostname()
        self.hostlock.release()
        return tmpval

    def set_audits_ok(self):
        self.audits = Health.OK

    def set_audits_down(self):
        self.audits = Health.DOWN

    def __add_audits_to_document(self):
        if self.audits == Health.DOWN:
            if self.health.get_health() == Health.OK:
                self.health.set_health(Health.DEGRADED)

            if self.health.has_symptom(Symptom.NONE_AUDIT):
                self.health.clear_health_symptoms()

            self.health.add_health_symptom(Symptom.NO_AUDITS)

        self.health.set_value("audits", self.audits)


#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
