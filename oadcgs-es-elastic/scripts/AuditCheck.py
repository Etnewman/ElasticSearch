# -*- coding: utf-8 -*-
#                                          Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class holds health information about a host.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: AuditCheck.py
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
# from Document import Document, Health
from Outfile import *
from ElasticConnection import ElasticConnection
import constants
import time
import datetime
import socket
import Watcher
from Host import Host
from ElasticInfo import ElasticInfo
from Document import DocType, Health, Symptom
from threading import Thread


class AuditCheck(Thread):

    # Static Class Variable
    nextRun = 0

    # Constructor
    def __init__(self):

        Thread.__init__(self)
        hostname = socket.gethostname()
        self.site = hostname[0:3].upper()
        self.conn = ElasticConnection()
        elastic_info = ElasticInfo()
        self.hostsdict = elastic_info.get_hostDict()

        # This query looks for hosts in winlogbeat and dcgs-syslog indexes
        # and is constrained by site and time range
        self.log_query = {
            "aggs": {"hosts": {"terms": {"field": "host.name", "size": 10000}}},
            "size": 0,
            "query": {
                "bool": {
                    "must": [{"match": {"DCGS_Site": self.site}}],
                    "filter": [
                        {
                            "range": {
                                "@timestamp": {
                                    "format": "strict_date_optional_time",
                                    "gte": constants.AUDITS_QUERY_TIME,
                                    "lte": "now",
                                }
                            }
                        }
                    ],
                }
            },
        }

        # This query looks for hosts and audits in current-healthdata
        # and is constrained by site and DocSubtype of host
        self.health_query = {
            "query": {
                "bool": {
                    "must": [
                        {"match": {"DCGS_Site": self.site}},
                        {"match": {"metadata.DocSubtype": "host"}},
                    ]
                }
            },
            "fields": ["host.name", "audits"],
            "_source": False,
            "size": 10000,
        }

    #
    # Static method to get next run time
    #
    @staticmethod
    def set_next_runtime():
        return time.time() + 300

    #
    # Static method to run AuditCheck when its time
    #
    @staticmethod
    def timetorun():
        retval = False
        # Initialize nextRun if 0
        if AuditCheck.nextRun == 0:
            AuditCheck.nextRun = AuditCheck.set_next_runtime()

        curtime = time.time()
        if curtime > AuditCheck.nextRun:
            retval = True
            AuditCheck.nextRun = AuditCheck.set_next_runtime()
            # print(
            #     "####AuditCheck: next run will be - ",
            #     datetime.datetime.fromtimestamp(AuditCheck.nextRun),
            # )
        return retval

    #
    # This function is called on startup and set to "intializing"
    # then updated with "OK" or "Down"
    #
    def update_audit_values(self):
        try:
            values = self.conn.es.search(
                index="dcgs-current-healthdata*", body=self.health_query
            )
            for host in values["hits"]["hits"]:
                if "audits" in host["fields"]:
                    # Set "audits" to "OK"
                    if Health.OK in host["fields"]["audits"]:
                        self.get_host_rec(
                            host["fields"]["host.name"][0]
                        ).set_audits_ok()
                    # Set "audits" to "DOWN"
                    elif Health.DOWN in host["fields"]["audits"]:
                        self.get_host_rec(
                            host["fields"]["host.name"][0]
                        ).set_audits_down()

        except Exception as e:
            print("ERROR: Unable to connect to Elastic and update audit values")
            print("EXCEPTION:", str(e))

    #
    # Get hosts from currrent-healtdata index
    #
    def get_health_hosts(self):
        health_hosts = []

        try:
            host_records = self.conn.es.search(
                index="dcgs-current-healthdata*", body=self.health_query
            )
            for host in host_records["hits"]["hits"]:
                # make sure key name is lower case and only up to first dot
                health_hosts.extend(host["fields"]["host.name"])

        except Exception as e:
            print("ERROR: Unable to connect to Elastic to get healthdata")
            print("EXCEPTION:", str(e))

        return health_hosts

    #
    # Get hosts from dcgs-syslog and winlogbeat index
    #
    def get_log_hosts(self):
        result = []
        hosts = []

        try:
            # define the index to search
            indexes = ["dcgs-syslog-iaas-ent*", "winlogbeat-*"]
            log_hosts = []
            for index in indexes:
                result = self.conn.es.search(index=index, body=self.log_query)
                for hosts in result["aggregations"]["hosts"]["buckets"]:
                    # make sure key name is lower case and only up to first dot
                    log_hosts.append(hosts["key"].lower().split(".")[0])

        except Exception as e:
            print(
                "ERROR: Unable to connect to Elastic to get syslog and winlogbeat hosts"
            )
            print("EXCEPTION:", str(e))

        return log_hosts

    #
    # Returns values that exist in list current_hosts but not in list hosts_with_audits
    #
    def noaudit_hosts(self, hosts_with_audits, current_hosts):
        noaudit_hosts = list(set(current_hosts).difference(set(hosts_with_audits)))
        return noaudit_hosts

    #
    # Updates host dictionary
    #
    def get_host_rec(self, name):
        if not name in self.hostsdict.keys():
            hostrec = Host(name)
            self.hostsdict[name] = hostrec
        else:
            hostrec = self.hostsdict[name]

        return hostrec

    def run(self):
        hosts_with_audits = self.get_log_hosts()
        current_hosts = self.get_health_hosts()
        hosts_with_noaudits = self.noaudit_hosts(hosts_with_audits, current_hosts)

        for host in hosts_with_audits:
            self.get_host_rec(host).set_audits_ok()

        for host in hosts_with_noaudits:
            self.get_host_rec(host).set_audits_down()
