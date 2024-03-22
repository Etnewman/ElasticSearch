# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class holds information and methods for threads running in the
#          Elastic Data Collector
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: ThreadInfo.py
#
# Location: /etc/logstash/scripts
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Robert Williamson, 2023-07-21: Original Version
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
# Frequency: created when the Data Collector starts running
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
from datetime import datetime


class ThreadInfo:

    # Constructor
    def __init__(self, thread):
        self.num_restarts = 0
        self.thread = thread
        self.name = thread.getName()
        self.starttime = datetime.now()
        self.total_restarts = 0
        self.restarted = False

    def increment_num_restarts(self):
        self.num_restarts = self.num_restarts + 1
        self.total_restarts = self.total_restarts + 1

    def clear_num_restarts(self):
        self.num_restarts = 0

    def get_num_restarts(self):
        return self.num_restarts

    def get_total_restarts(self):
        return self.total_restarts

    # returns boolean that shows if thread has been restarted
    def get_restarting(self):
        return self.restarted

    def set_restarting(self, status):
        self.restarted = status

    def get_thread_uptime(self):
        return datetime.now() - self.starttime

    def reset_starttime(self):
        self.starttime = datetime.now()

    def get_thread(self):
        return self.thread
