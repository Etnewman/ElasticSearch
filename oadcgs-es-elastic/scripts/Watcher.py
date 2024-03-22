# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class monitors a file created and constantly updated by
#          logstah containing host and application information for all
#          hosts and any applications that have been configured for
#          monitoring.  The class update the host in the host dictionary
#          and updates any applications that are in the application
#          dictionary and then creates a health document for the host.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: Watcher.py
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
import datetime
from threading import Thread
from Host import Host
from Outfile import Outfile
import constants
import os
import time
from time import strptime
import sys
import json
import traceback
import glob


class Watcher(Thread):
    # Constructor
    def __init__(self, hosts, apps, fpath, fprefix):
        Thread.__init__(self)
        self.hosts = hosts
        self.apps = apps
        self.inpath = fpath
        self.fileprefix = fprefix
        self.lastfile = constants.WATCHER_FILE_POS
        self.outfile = Outfile(constants.HEALTH_METRICS_OUT, "watcher")

    # Method: run - run method for Thread.
    #
    # Parameters:
    #   None
    # Returns:
    #   None
    def run(self):
        # print "run method - executing device: ", self.devicetype
        try:
            self.setName("Watcher")
            self.process_hosts()
        except:
            traceback.print_exc()
        # print "exiting thread"

    def process_hosts(self):
        fname = self.inpath + "/" + self.fileprefix
        for l in self.follow(fname):
            # print ("LINE: {}".format(l))
            # Try-Catch block in case of malformed json file
            try:
                # processing of host now relegated to another function
                self.process_line(l)
            except json.decoder.JSONDecodeError as e:
                print(f"Error processing line: {e}")
                print(f"Problematic line: {l}")

    def process_line(self, line):
        jval = json.loads(line)
        hname = jval["host"]["name"]
        # make sure key name is lower case and only up to first dot
        hname = hname.lower().split(".")[0]
        # print("watcher: processing hosts: ", hname)
        if not hname in self.hosts.keys():
            h = Host(hname, jval)
            self.hosts[hname] = h
        else:
            h = self.hosts[hname]
            h.update_host(jval)

        for app in jval["Applications"]:
            longname = app["Name"]
            shortname = longname.split("_")[0]
            if shortname in self.apps.keys():
                self.apps[shortname].update_app(hname, app, h.get_lastupdate_time())

        # write host health document
        self.outfile.output(h.get_healthdoc())

    def updatelast(self, fname, t=None):
        retval = 0
        if t == None:
            try:
                lastfile = open(self.lastfile, "r")
                line = lastfile.read()
                vals = line.split(":")
                if vals[1] == fname:
                    retval = int(vals[0])
            except:
                print(
                    "Error extracting file postion, resetting to beginning of file: ",
                    fname,
                )
        else:
            lastfile = open(self.lastfile, "w")
            lastfile.write(str(t) + ":" + fname)

        return retval

    def update_filename(self, fname):
        tnow = datetime.datetime.now()
        tstr = tnow.strftime("%Y-%m-%d")
        name = fname + tstr + ".json"
        return name

    def get_filehandle(self, name):
        try:
            print("**** OPENING FILE - ", name)
            fh = open(name, "r")
            self.cleanup_old_files()
        except IOError:
            print("*** File not Accessible:", name)
            fh = None
        except:
            fh = None
        return fh

    def cleanup_old_files(self):
        fnames = self.inpath + "/" + self.fileprefix + "*"

        age = (time.time()) - 2 * 86400

        print("***************CHECKING FNAMES", fnames)
        files = glob.glob(fnames)
        for file in files:
            print("***************CHECKING FILES", file)
            if os.path.getmtime(file) < age:
                os.remove(file)

    def follow(self, name):
        currentname = self.update_filename(name)
        current = self.get_filehandle(currentname)
        if current != None:
            current.seek(self.updatelast(currentname))

        while True:
            if current != None:
                while True:
                    # print ("current name", currentname)
                    line = current.readline()
                    if not line:
                        break
                    self.updatelast(currentname, current.tell())
                    yield line

            newname = self.update_filename(name)
            if newname != currentname:
                currentname = newname
                if current != None:
                    current.close()
                    current = None

            if current == None:
                try:
                    current = self.get_filehandle(currentname)
                except IOError:
                    pass
            time.sleep(5)


def main():

    inpath = "/ELK-local/metrics_in"
    fileprefix = "hosthealth-"

    # Host Dictionary
    myhost = {}
    Apps = {}
    hu = Watcher(myhost, Apps, inpath, fileprefix)
    hu.start()


if __name__ == "__main__":
    main()

#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
