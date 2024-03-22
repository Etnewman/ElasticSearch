# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class is a helper class used to read the application
#          configurations.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: AppConfigReader.py
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
# Use: This class is part of the elasticDataCollector python application
#      which runs as a service on Logstash VMs
#
# Users: Not for use by users.
#
# DAC Setting: 755 root root
#
# Frequency: Reads config on application startup
#
# Information Security Authorization
# ACC/A26 IA Approval: year-mm-dd, Name, ACC ISSE
#
# Lead System Engineering Authorization
# AF-DCGS LSE Approval: year-mm-dd, Name, AF-DCGS/AO
#
###########################################################################
#
from configparser import SafeConfigParser


class AppConfigReader:
    def __init__(self, fname):
        parser = SafeConfigParser()
        parser.read(fname)
        self.Apps = {}

        for apps in parser.sections():
            newapp = {}
            for name, value in parser.items(apps):
                appvals = {}
                appvals["lastupdate"] = 0
                appvals["effect"] = value
                newapp[name] = appvals
            self.Apps[apps] = newapp

    def get_apps(self):
        print("In Get Apps", type(self.Apps))
        return self.Apps


#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
