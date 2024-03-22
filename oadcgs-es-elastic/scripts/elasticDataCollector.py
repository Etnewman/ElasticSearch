#!/etc/logstash/scripts/venv/bin/python
# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This is the entry point for the elastic data collector application.
#          This file is called by the elasticDataCollector service to start
#          the application.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: elasticDataCollector.py
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
# Frequency: Should be continually running on each Logstash instance
#
# Information Security Authorization
# ACC/A26 IA Approval: year-mm-dd, Name, ACC ISSE
#
# Lead System Engineering Authorization
# AF-DCGS LSE Approval: year-mm-dd, Name, AF-DCGS/AO
#
###########################################################################
#
from DeviceInfo import DeviceInfo, SNMPDeviceInfo, Devices
from Device import DeviceType, Device
from Isilon import Isilon
from Xtremio import Xtremio
from CiscoSwitch import CiscoSwitch
from DataDomain import DataDomain
from DellIdrac import DellIdrac
from Document import Document, Health, DocType, DocSubtype, Symptom
from Fx2 import Fx2
from Watcher import Watcher
from Outfile import Outfile
from Querier import Querier
from Vsphere import Vsphere
from App import App
from Group import Group
from AppConfigReader import AppConfigReader
from GroupConfigReader import GroupConfigReader
from ACAS import ACAS
from DLP import DLP
from os.path import exists
from datetime import datetime, timedelta
import time
import constants
import os
import sys
import json
import threading
import time
import socket
from ElasticInfo import ElasticInfo
from DataCollectorListener import DataCollectorListener
from AuditCheck import AuditCheck
from ThreadInfo import ThreadInfo


def main():

    if sys.version_info.major != 3:
        print("Script needs python version 3")
        exit()

    # instantiate ElasticInfo and AuditCheck object
    elastic_info = ElasticInfo()
    achecker = AuditCheck()
    achecker.update_audit_values()

    if os.path.isfile(constants.MAIN_DEVICE_CONF):
        with open((constants.MAIN_DEVICE_CONF), "r") as devicefile:
            config = json.load(devicefile)

        for device in config["devices"]:
            mydev = DeviceInfo()
            mydev.loadjson(json.dumps(device))

            if device["devicetype"] == DeviceType.ISILON:
                elastic_info.add_thread(Isilon(mydev))
            elif device["devicetype"] == DeviceType.XTREMIO:
                elastic_info.add_thread(Xtremio(mydev))
            elif (
                device["devicetype"] == DeviceType.NEXUS5K
                or device["devicetype"] == DeviceType.NEXUS7K
                or device["devicetype"] == DeviceType.CATALYST
            ):
                elastic_info.add_thread(CiscoSwitch(mydev))
            elif device["devicetype"] == DeviceType.FX2:
                elastic_info.add_thread(Fx2(mydev))
            elif device["devicetype"] == DeviceType.DATADOMAIN:
                elastic_info.add_thread(DataDomain(mydev))
            elif (
                device["devicetype"] == DeviceType.FC630
                or device["devicetype"] == DeviceType.R630
            ):
                elastic_info.add_thread(DellIdrac(mydev))
            elif device["devicetype"] == DeviceType.DLP:
                elastic_info.add_thread(DLP(mydev))

            # print(json.dumps(mydev, default=lambda o:o.__dict__, indent=4))
    else:
        print(
            "Warning: No devices configured for monitoring at this site. Expected: ",
            constants.MAIN_DEVICE_CONF,
        )

    # Initialize Application Dictionary from config file
    appsToMonitor = AppConfigReader(constants.APPS_CONF).get_apps()
    for app in appsToMonitor:
        elastic_info.add_app(app, appsToMonitor[app])

    # Initialize Host Dictionary, it will be filled in by
    # the Watcher and Querier threads
    watcher = Watcher(
        elastic_info.get_hostDict(),
        elastic_info.get_appDict(),
        constants.HEALTH_METRICS_IN,
        "hosthealth-",
    )
    elastic_info.add_thread(watcher)

    # Initialize Group Dictionary from config file
    groupsToMonitor = GroupConfigReader(constants.GRPS_CONF).get_groups()
    for group in groupsToMonitor:
        group_hosts = groupsToMonitor[group]["group_hosts"]
        group_min = groupsToMonitor[group]["group_min"]
        elastic_info.add_group(group, group_hosts, group_min)

    querier = Querier(elastic_info.get_hostDict())
    elastic_info.add_thread(querier)

    elastic_info.add_thread(Vsphere())

    elastic_info.add_thread(DataCollectorListener())

    # Start all the threads
    for thread in elastic_info.get_threadlist():
        thread.start()
        time.sleep(0.25)
        print("Started collection for : ", thread.getName())
        elastic_info.threadDict[thread.getName()] = ThreadInfo(thread)

    num_threads = threading.active_count()
    while num_threads != 0:
        for thread in elastic_info.get_threadlist():
            num_restarts = elastic_info.threadDict[thread.getName()].get_num_restarts()
            # check if the thread is running, if not try to restart it and increment num_restarts
            if not thread.is_alive() and (num_restarts < constants.MAX_RESTARTS):
                print(
                    "\nThread: ",
                    thread.getName(),
                    " Died unexpectidly, thread restating",
                )

                elastic_info.restart_thread(thread)
                elastic_info.threadDict[thread.getName()].increment_num_restarts()
                elastic_info.threadDict[thread.getName()].set_restarting(True)
                elastic_info.add_problem_thread(thread.getName(), Symptom.RESTARTING)

            # if the thread has restarted max times unsucessfully, report it to Elastic
            elif not thread.is_alive() and (num_restarts == constants.MAX_RESTARTS):
                print(
                    "\nThread: ",
                    thread.getName(),
                    " Died unexpectidly, application needs to be restarted",
                )
                elastic_info.add_problem_thread(thread.getName(), Symptom.NOT_RUNNING)

            # if the thread is alive and run for a certain amount of time, report it to Elastic and clear num_restarts
            elif (
                thread.is_alive()
                and (
                    elastic_info.threadDict[thread.getName()].get_thread_uptime()
                    >= timedelta(minutes=constants.RESTART_TIME_THRESHOLD)
                )
                and (elastic_info.threadDict[thread.getName()].get_restarting() == True)
            ):
                elastic_info.threadDict[thread.getName()].clear_num_restarts()
                elastic_info.threadDict[thread.getName()].set_restarting(False)
                elastic_info.add_ok_thread(thread.getName())

            # if the thread is alive and has not been flagged as restarted, report it to Elastic
            else:
                elastic_info.add_ok_thread(thread.getName())

        # Sleep first to give Apps a chance to be updated
        time.sleep(60)

        # create data collector health doc, and health docs for all apps and groups
        elastic_info.write_outputs()

        num_threads = threading.active_count()

        if AuditCheck.timetorun():
            achecker = AuditCheck()
            achecker.start()


if __name__ == "__main__":
    main()
#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
