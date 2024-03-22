# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class handles API requests sent to the DataCollectorListener class
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: RequestHandler.py
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
# Use: This class is intantiated in DataCollectorListener.py
#
# Users: Not for use by users.
#
# DAC Setting: 755 root root
#
# Frequency: whenever an API request is sent to DataCollectorListener
#
# Information Security Authorization
# ACC/A26 IA Approval: year-mm-dd, Name, ACC ISSE
#
# Lead System Engineering Authorization
# AF-DCGS LSE Approval: year-mm-dd, Name, AF-DCGS/AO
#
###########################################################################
#
from http.server import BaseHTTPRequestHandler, HTTPServer
import time
import sys
import json
import os
from threading import Thread
from ElasticInfo import ElasticInfo


class RequestHandler(BaseHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        self.elastic_info = ElasticInfo()
        super().__init__(*args, **kwargs)

    def __send_api_response(self, message, status, style):
        self.send_response(status)
        self.send_header("Content-Type", style)
        self.end_headers()
        self.wfile.write(message.encode("utf-8"))

    def __add_version(self, message):
        message.append({"version": self.elastic_info.get_version()})
        return json.dumps(message, indent=2)

    def do_GET(self):
        if self.path == "/threads.ok":
            message = self.elastic_info.get_ok_threads()
            message.append({"num_ok_threads": self.elastic_info.get_num_ok_threads()})
            message = self.__add_version(message)
            self.__send_api_response(message, 200, "application/json")

        elif self.path == "/":
            message = json.dumps(self.elastic_info.get_healthDict(), indent=2)
            self.__send_api_response(message, 200, "application/json")

        elif self.path == "/threads.problem":
            message = self.elastic_info.get_problem_threads()
            message.append(
                {"num_problem_threads": self.elastic_info.get_num_problem_threads()}
            )
            message = self.__add_version(message)
            self.__send_api_response(message, 200, "application/json")
        elif self.path == "/uptime":
            message = {
                "Started": self.elastic_info.get_starttime(),
                "Uptime": self.elastic_info.get_uptime(),
                "version": self.elastic_info.get_version(),
            }
            message = json.dumps(message, default=str, indent=2)
            self.__send_api_response(message, 200, "application/json")

        else:
            message = "ERROR: Request not supported." + os.linesep
            self.__send_api_response(message, 404, "text/html")
