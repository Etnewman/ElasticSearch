# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class holds information about the Elastic Data Collector.
#          It holds information on Apps, Hosts, Groups, and Threads running
#          in the data collector. It also provides several useful methods
#          related to this information.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: ElasticInfo.py
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
import time
from App import App
from Group import Group
import os
import sys
import json
from datetime import datetime
from threading import Thread, Lock
import threading
from Document import Document, Health, DocType, DocSubtype, Symptom
import socket
import constants
from Outfile import Outfile
import version
from ThreadInfo import ThreadInfo
from Device import DeviceType, Device
from Isilon import Isilon
from Xtremio import Xtremio
from CiscoSwitch import CiscoSwitch
from DataDomain import DataDomain
from DellIdrac import DellIdrac
from Fx2 import Fx2
from Watcher import Watcher
from Outfile import Outfile
from DLP import DLP


class Singleton(type):
    _instances = {}

    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            instance = super(Singleton, cls).__call__(*args, **kwargs)
            cls._instances[cls] = instance
        return cls._instances[cls]


class ElasticInfo(metaclass=Singleton):

    # Constructor
    def __init__(self):
        self.starttime = datetime.now()
        self.threadlist = list()
        self.appDict = {}
        self.hostDict = {}
        self.groupDict = {}
        self.problem_threads = {}
        self.ok_threads = {}
        self.healthDict = {}
        self.status = ""
        self.outfile = Outfile(constants.HEALTH_METRICS_OUT, "edc_info")
        self.dc_health_doc = Document(
            DocType.HEALTH, DocSubtype.DATA_COLLECTOR, None, socket.gethostname()
        )
        self.version = version.VERSION
        self.symptoms = list()
        self.threadDict = {}

    def get_num_threads(self):
        return len(self.threadlist)

    # method to restart data collector threads if they die
    def restart_thread(self, thread):
        from Vsphere import Vsphere
        from Querier import Querier
        from DataCollectorListener import DataCollectorListener

        if (
            isinstance(thread, DataDomain)
            or isinstance(thread, Isilon)
            or isinstance(thread, Xtremio)
            or isinstance(thread, DellIdrac)
            or isinstance(thread, CiscoSwitch)
            or isinstance(thread, Fx2)
            or isinstance(thread, DLP)
        ):
            new_thread = type(thread)(thread._devinfo)

        elif isinstance(thread, Watcher):
            new_thread = type(thread)(
                thread.hosts, thread.apps, thread.inpath, thread.fileprefix
            )

        elif isinstance(thread, DataCollectorListener):
            new_thread = type(thread)()

        elif isinstance(thread, Vsphere):
            new_thread = type(thread)()

        elif isinstance(thread, Querier):
            new_thread = type(thread)(thread.hosts)

        new_thread.daemon = thread.daemon
        # update threadlist with new thread
        self.threadDict[thread.getName()].thread = new_thread
        self.threadDict[thread.getName()].starttime = datetime.now()
        threading.Thread.start(new_thread)

    def get_num_problem_threads(self):
        return len(self.problem_threads)

    def get_num_ok_threads(self):
        return len(self.ok_threads)

    def get_threadlist(self):
        threadlist = list()
        for thread in list(self.threadDict.values()):
            threadlist.append(thread.thread)
        return threadlist

    # add thread to thread dictionary
    def add_thread(self, newthread):
        threadInfoInstance = ThreadInfo(newthread)
        self.threadDict[threadInfoInstance.name] = threadInfoInstance

    def add_ok_thread(self, newthread):
        if newthread in self.problem_threads:
            self.problem_threads.pop(newthread)
        self.ok_threads[newthread] = ""

    def add_problem_thread(self, newthread, symptom):
        if newthread in self.ok_threads:
            self.ok_threads.pop(newthread)
        self.problem_threads[newthread] = symptom

    def get_ok_threads(self):
        return list(self.ok_threads.keys())

    def get_problem_threads(self):
        return list(self.problem_threads.keys())

    def get_uptime(self):
        return datetime.now() - self.starttime

    def get_starttime(self):
        return self.starttime

    def get_appDict(self):
        return self.appDict

    def add_app(self, app, appToMonitor):
        self.appDict[app] = App(app, appToMonitor)

    def get_groupDict(self):
        return self.groupDict

    def add_group(self, group, group_hosts, group_min):
        self.groupDict[group] = Group(group, group_hosts, group_min, self.hostDict,)

    def get_hostDict(self):
        return self.hostDict

    def get_version(self):
        return self.version

    def create_app(self):
        app = {}
        app["Name"] = "Data Collector"
        app["Status"] = self.status
        app["HealthSymptoms"] = self.get_symptoms()

        if self.get_num_symptoms() == 0:
            app["HealthSymptoms"] = "None"

        return app

    def create_threads(self):
        threads = {}
        threads["ok"] = {}
        threads["problem"] = {}

        threads["total"] = self.get_num_threads()

        threads["ok"]["names"] = self.get_ok_threads()
        threads["ok"]["count"] = self.get_num_ok_threads()

        threads["problem"]["names"] = self.get_problem_threads()
        threads["problem"]["count"] = self.get_num_problem_threads()

        if self.get_num_problem_threads() == 0:
            threads["problem"]["names"] = "None"

        return threads

    def update_healthDict(self):
        self.set_status()

        self.healthDict = {
            "app": self.create_app(),
            "version": self.version,
            "threads": self.create_threads(),
        }

    def get_healthDict(self):
        return self.healthDict

    def get_num_symptoms(self):
        return len(self.symptoms)

    def get_symptoms(self):
        return self.symptoms

    def set_status(self):
        self.status = "OK"

        self.symptoms = list(self.problem_threads.values())
        if len(self.symptoms) > 0:
            self.status = "Degraded"

    def write_outputs(self):
        self.update_healthDict()
        # set values of outdoc and write it to the outfile
        for name, val in self.get_healthDict().items():
            self.dc_health_doc.set_value(name, val)
        self.dc_health_doc.set_value(
            "@timestamp", datetime.utcnow().isoformat(sep="T") + "Z"
        )
        self.outfile.output(self.dc_health_doc)

        # go through apps and create a health doc for each one
        for app in self.get_appDict():
            try:
                self.outfile.output(self.get_appDict()[app].get_healthdoc())
            except:
                print("Error getting health for app: ", app)

        # go through groups and create a healthdoc for each one
        for group in self.get_groupDict():
            try:
                self.outfile.output(self.get_groupDict()[group].get_healthdoc())
            except:
                print("Error getting health for group: ", group)
