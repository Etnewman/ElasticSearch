# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class creates a RequestHandler server and has that instance serve API requests
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: DataCollectorListener.py
#
# Location: /etc/logstash/scripts
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Robert Williamson, 2023-01-26: Original Version
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
from ElasticInfo import ElasticInfo
from RequestHandler import RequestHandler
from threading import Thread
from http.server import BaseHTTPRequestHandler, HTTPServer
import time
import constants


class DataCollectorListener(Thread):

    # Constructor
    def __init__(self):
        Thread.__init__(self)
        self.hostname = constants.DATACOLLECTOR_API_HOST
        self.port = constants.DATACOLLECTOR_API_PORT

    # Runs the thread that listens for API requests on localhost:9601
    def run(self):
        self.setName("DataCollectorListener")
        web_server = HTTPServer((self.hostname, self.port), RequestHandler)
        web_server.serve_forever()
