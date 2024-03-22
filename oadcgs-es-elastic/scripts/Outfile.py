# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class is a helper class used write docunents to output
#          files.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: Outfile.py
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
# Frequency: Used by all threads that create documents
#
# Information Security Authorization
# ACC/A26 IA Approval: year-mm-dd, Name, ACC ISSE
#
# Lead System Engineering Authorization
# AF-DCGS LSE Approval: year-mm-dd, Name, AF-DCGS/AO
#
###########################################################################
#
import os
import constants
import gzip
from datetime import datetime
from glob import glob, glob1
from subprocess import check_call
import traceback


class Outfile:
    def __init__(self, path, name):
        self.outpath = path
        self.filename = name + ".json"
        self.outfile = None
        self.fullpath = self.outpath + "/" + self.filename

    def output(self, item):
        if item is not None:
            try:
                with open((self.fullpath), "a+") as self.outfile:
                    if isinstance(item, dict):
                        for key in item:
                            self.outfile.write(item[key].toJSON())
                            self.outfile.write("\n")
                    elif isinstance(item, list):
                        for val in item:
                            self.outfile.write(val.toJSON())
                            self.outfile.write("\n")
                    else:
                        self.outfile.write(item.toJSON())
                        self.outfile.write("\n")
            except:
                print("Outfile: Exception writing data to: ", self.fullpath)
                traceback.print_exc()

            self.backup()

    # Method: backup - backup json file
    # Parameters:
    #   None
    # Returns:
    #   None
    def backup(self):
        # See if json file exists
        if os.path.isfile(self.fullpath):
            # if json file is greater than size
            if os.stat(self.fullpath).st_size > int(constants.DEVICE_BKPS_SIZE):
                # print("Rotating File: ", self.fullpath)
                count = len(glob1(self.outpath, self.filename + "-" + "*"))
                # If more than constants.DEVICE_BKPS backup files exist delete oldest
                if count >= constants.DEVICE_BKPS:
                    list_of_files = glob(self.outpath + "/" + self.filename + "-*")
                    oldest = min(list_of_files, key=os.path.getmtime)
                    # Remove oldest then create new backup archive
                    try:
                        os.unlink(oldest)
                    except:
                        traceback.print_exc()

                # Create new backup
                bnamebak = (
                    self.fullpath + "-" + datetime.now().strftime("%Y%m%d-%H%M%S")
                )
                if not self.outfile.closed:
                    self.outfile.close()
                try:
                    os.rename(self.fullpath, bnamebak)
                    check_call(["gzip", bnamebak])
                except:
                    traceback.print_exc()


#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
