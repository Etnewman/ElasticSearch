# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class monitors the ACAS vulnerability scanner system on DCGS
#          and sends that information to the Elastic Data Collector. This
#          class is run as a thread as part of the Data Collector.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: ACAS.py
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
from Document import Document, Health
from Outfile import *
from datetime import datetime, timedelta
from tenable.sc import *
from ElasticConnection import ElasticConnection
from Crypt import Crypt
import time
import constants
import traceback
import os
import sys


class ACAS:
    # Constructor
    def __init__(self):
        self.outfile = Outfile(constants.HEALTH_METRICS_OUT, "acas")

        self.conn = ElasticConnection()

        # Create list for acas keys
        acas_list = []

        # Try to open acas.dat, if its not there exit
        try:
            if os.stat(constants.ACAS_DAT).st_size == 0:
                print(
                    "ERROR : Unable to start ACAS collector. Data file acas.dat is empty, no ACAS API Keys found."
                )
                sys.exit(1)

            count = 0
            with open(constants.ACAS_DAT, "r") as f:
                for line in f:
                    if count < 2:
                        line = Crypt().decode(line.strip())
                    acas_list.append(line.strip())
                    count += 1

        except:
            print(
                "ERROR : Unable to start ACAS collector. Data file acas.dat not found."
            )
            sys.exit(2)

        # acas_list[0] and [1] are API keys for service account
        # acas_list[2] is the hostname
        # Create API variable that connects to ACAS using API keys
        self.sc = TenableSC(
            acas_list[2], access_key=acas_list[0], secret_key=acas_list[1],
        )

    # Method: scan_query - Queries the most recent scan completed on ACAS
    #
    # Parameters:
    #   None
    # Returns:
    #   None
    def scan_query(self):
        outdoc = Document("acas", "vuln", None, None)

        # Use API to get list of scan results with the finishTime field, then filter scans within the last 7 days
        for scan in self.sc.scan_instances.list(fields=["finishTime"])["usable"]:
            time = datetime.fromtimestamp(float(scan["finishTime"]))
            if (time.now() - time) < timedelta(days=7):
                # Get the vulnerability information from scans in the last 7 days
                for vuln in self.sc.analysis.scan(scan["id"], ("severity", "=", "3,4")):
                    outdoc.set_value("vuln", vuln)
                    self.outfile.output(outdoc)

    # Method: scanner_status - Queries the status of all vulnerability scanners on ACAS
    #
    # Parameters:
    #   None
    # Returns:
    #   None
    def scanner_status(self):
        outdoc = Document("acas", "scanner_status", None, None)

        # Get a list of all vulnerability scanners on ACAS
        for scanner in self.sc.scanners.list():
            # Get the details and status of each scanner on ACAS
            outdoc.set_value("scanner_status", self.sc.scanners.details(scanner["id"]))
            self.outfile.output(outdoc)

    # Method: scan_query - Queries the status of the ACAS system
    #
    # Parameters:
    #   None
    # Returns:
    #   None
    # THIS PORTION REQUIRES ADMIN PASSWORD
    # def system_status(self):
    #    outdoc = Document("acas", "system_status", None, None)
    # Get the status of the ACAS system
    #    outdoc.set_value("system_status", self.sc.system.status())
    #    self.outfile.output(outdoc)

    # Method: test_conn - Tests the connection to ACAS for API Keys Testing
    #
    # Parameters:
    #   None
    # Returns:
    #   None
    def test_conn(self):
        try:
            var = self.sc.credentials.list()
            print("SUCCESS: API KEYS CONNECTED TO ACAS")
        except:
            print("ERROR: API KEYS NEED RECONFIGURED")

    # Method: delete_acas_index - Deletes the ACAS index for new data
    #
    # Parameters:
    #   None
    # Returns:
    #   None
    def delete_acas_index(self):
        self.conn.es.indices.delete(index="dcgs-acas-iaas-ent", ignore=[400, 404])

    # Method: run - runs the thread that collects all the information for acas
    #
    # Parameters:
    #   None
    # Returns:
    #   None
    def run(self):
        try:
            self.query_data()

        except:
            traceback.print_exc()

    def query_data(self):
        self.delete_acas_index()
        self.scan_query()
        self.scanner_status()
        # self.system_status()


if __name__ == "__main__":
    ACAS = ACAS()
    args = sys.argv[1:]
    if len(args) != 0:
        if args[0] == "-t":
            ACAS.test_conn()
        else:
            print("Usage: ACAS.py [-t] for testing connection with API keys")
    else:
        ACAS.run()
