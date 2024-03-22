# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class queries heartbeat information from elasticsearch
#          and then updates each host with the ping status returned.
#          If the return value of the update is Unknown or Down then
#          this class creates a health document for the host.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: Querier.py
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
# Frequency: runs as a thread in the elasticDataCollector app
#
# Information Security Authorization
# ACC/A26 IA Approval: year-mm-dd, Name, ACC ISSE
#
# Lead System Engineering Authorization
# AF-DCGS LSE Approval: year-mm-dd, Name, AF-DCGS/AO
#
###########################################################################
#
from threading import Thread
import traceback
import Host
import Outfile
from time import time, ctime
from Host import *
from Outfile import *
from ElasticConnection import ElasticConnection
import constants
import socket
from ElasticInfo import ElasticInfo
from Document import Symptom


class Querier(Thread):
    def __init__(self, hosts):
        Thread.__init__(self)
        self.elastic_info = ElasticInfo()
        self.hosts = hosts
        self.outfile = Outfile(constants.HEALTH_METRICS_OUT, "querier")

        hostname = socket.gethostname()
        self.site = hostname[0:3].upper()

        self.query = (
            'SELECT url.domain, monitor.status FROM "heartbeat-*" WHERE DCGS_Site = \''
            + self.site
            + '\' AND monitor.type = \'icmp\' AND "@timestamp" > CURRENT_TIMESTAMP - INTERVAL 2 MINUTE ORDER BY "@timestamp" DESC'
        )

        # <----- set connection to Elastic ----->
        self.conn = ElasticConnection()

    def run(self):
        # print "run method - executing device: ", self.devicetype
        try:
            self.setName("Querier")
            self.query_data()
        except:
            traceback.print_exc()

    def query_data(self):

        while True:
            time.sleep(60)
            try:
                # Remove symptom from ElasticInfo if necessary
                self.elastic_info.add_ok_thread("Querier")
                self.get_elacData()
            except:
                print(
                    "Unable to query data from Elasticsearch, will try again in 60 seconds"
                )
                # Add symptoms to ElasticInfo
                self.elastic_info.add_problem_thread(
                    "Querier", Symptom.CONNECTION_ERROR
                )

    def get_elacData(self):

        # print("Quering Elastic...")
        # <----- Query Elastic ----->
        try_again = True
        while try_again:
            try:
                heart_capture = self.conn.sql_query(self.query)
                try_again = False
            except:
                try_again = self.conn.check_cluster_connection(try_again)

        # <----- parse Elastic captures ---->
        heart_master = heart_capture["rows"]

        # <----- declare hostname array --->
        heartbeat_hosts = {"host": []}

        # <----- append Elastic data to dict ----->
        num_nones = 0
        for item in heart_master:
            if item[0] is not None:
                hosttype = item[0][3:5].lower()
                if (
                    hosttype == "su"
                    or hosttype == "wm"
                    or hosttype == "sm"
                    or hosttype == "wu"
                ):
                    if item not in heartbeat_hosts["host"]:
                        heartbeat_hosts["host"].append(item)
            else:
                num_nones = num_nones + 1

        # print("Querier: Process heartbeat hosts...")
        # Check for empty reponse; if empty heartbeat not querying hosts properly
        if len(heart_master) == num_nones:
            print(
                "Querier-Warning: Possible issue with heartbeat ess.icmp.file, verify get_ldap_hosts.sh is working properly"
            )
            self.elastic_info.add_problem_thread("Querier", Symptom.EMPTY_RESPONSE)
        else:
            # <---- If a heartbeat host is not in hosts list this for loop will add it ----->
            for item in heartbeat_hosts["host"]:
                (hname, pingstatus) = item
                hname = hname.lower()  # make sure key name is lower case
                if not hname in self.hosts.keys():
                    # print("Querier Adding host: ", hname)
                    h = Host(hname)
                    self.hosts[hname] = h

                if self.hosts[hname].update_health(pingstatus):
                    self.outfile.output(self.hosts[hname].get_healthdoc())
                    # print("Querier: Adding doc for host:", hname)
            self.elastic_info.add_ok_thread("Querier")


def main():

    # Host Dictionary
    myhost = {}
    q = Querier(myhost)
    # q.start()
    q.get_elacData()


if __name__ == "__main__":
    main()

#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
