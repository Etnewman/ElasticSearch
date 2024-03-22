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

from ElasticConnection import ElasticConnection
from datetime import timedelta
import datetime
import requests
import constants
import constants
import socket


class StaleCleanup:

    # Constructor
    def __init__(self):
        self.conn = ElasticConnection()
        hostname = socket.gethostname()
        self.site = hostname[0:3].upper()
        self.clusters = self.conn.get_cluster_domains()

        stale_query = {
            "query": {
                "bool": {
                    "must": [
                        {"range": {"@timestamp": {"lte": constants.STALE_QUERY_TIME}}},
                        {"match": {"DCGS_Site": str(self.site)}},
                        {
                            "multi_match": {
                                "query": "Stale",
                                "fields": [
                                    "host.Health",
                                    "app.Health",
                                    "app.Status",
                                    "group.Health",
                                ],
                            }
                        },
                    ]
                }
            }
        }

        failover_query = {
            "query": {
                "multi_match": {
                    "query": "FAILOVER",
                    "fields": [
                        "host.Health",
                        "app.Health",
                        "app.Status",
                        "group.Health",
                    ],
                }
            }
        }

        self.queries = [
            {"index": "dcgs-current-healthdata-iaas-ent", "query": stale_query}
            # {"index": "dcgs-current-healthdata*", "query": failover_query},
        ]

    def __edc_ok(self):
        retval = False

        try:
            uptime = requests.get(
                "http://"
                + constants.DATACOLLECTOR_API_HOST
                + ":"
                + str(constants.DATACOLLECTOR_API_PORT)
                + "/uptime"
            )
            if uptime.status_code == 200:
                if self.__validate_time(uptime.json()["Uptime"]) > float(
                    constants.STALE_ELAC_UPTIME
                ):
                    retval = True

        except Exception as e:
            print("ERROR: Unable to send a request to the EDC API")
            print("EXCEPTION:", str(e))

        return retval

    def __get_num_docs(self, index, query):
        total_hits = 0
        try:
            total_hits = self.conn.es.search(index=index, body=query, size=0)["hits"][
                "total"
            ]["value"]

        except Exception as e:
            print("ERROR: Unable to connect to Elastic")
            print("EXCEPTION:", str(e))

        return total_hits

    def cleanup(self, index, query):
        if self.__edc_ok():
            size = self.__get_num_docs(index, query)
            if size > 0:
                docs = self.conn.es.search(index=index, body=query, size=size)
                print(docs)
                print()

                for doc in docs["hits"]["hits"]:
                    self.conn.es.delete(index=doc["_index"], id=doc["_id"])
        return 0

    def __validate_time(self, t):
        time = t.split(",")
        if len(time) == 2:
            days = int(time[0].split()[0])
            delta = timedelta(days=days)
        else:
            hours, minutes, seconds = time[0].split(":")
            delta = timedelta(
                hours=int(hours), minutes=int(minutes), seconds=float(seconds)
            )
        return delta.total_seconds()


if __name__ == "__main__":
    clean = StaleCleanup()

    for cluster in clean.clusters:
        if cluster == "wch":
            clean.conn.switch_secondary()
        for query in clean.queries:
            clean.cleanup(query["index"], query["query"])
