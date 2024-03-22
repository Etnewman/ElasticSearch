# -*- coding: utf-8 -*-
#                                   Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class queries events from vcenter using vsphere API. The
#          events are then written in json form to be ingested into
#          Elastic by filebeat.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: Vsphere.py
#
# Location: /etc/logstash/scripts
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Steve Truxal, 2022-01-07: Original Version
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
from Document import Document, DocType, Health, DocSubtype, Symptom
from Outfile import *
from Crypt import Crypt
from datetime import datetime, timedelta
from pyVim.connect import SmartConnectNoSSL
from pyVmomi import vim
import pyVmomi
import time
import constants
import socket
from ElasticInfo import ElasticInfo


class Vsphere(Thread):
    def __init__(self):
        Thread.__init__(self)
        self.elastic_info = ElasticInfo()
        self.outfile = Outfile(constants.HEALTH_METRICS_OUT, "vsphere")
        try:
            with open(constants.VSPHERE_DAT, "r") as pwfile:
                rawdata = pwfile.read().replace("\n", "")
                data = rawdata.split(":")
                self.quser = data[0]
                self.qpasswd = Crypt().decode(data[1])
        except:
            print(
                "Vsphere: Fatal Error: Could not retreive password from",
                constants.VSPHERE_DAT,
                " for access to vsphere(vcenter)",
            )
            exit()

        self.vcenterHost = socket.getfqdn(socket.gethostname()[:3] + "av01vc01")

        self.last_eventquery_file = constants.VSPHERE_LAST_EVENT_QUERY

        # create list of tags(fields) that we want to process
        self.tags = [
            "host",
            "datacenter",
            "computeResource",
            "vm",
            "ds",
            "net",
            "dvs",
            "entity",
            "source",
            "alarm",
        ]

        self.connected = False
        self.__connect()

    def __connect(self):
        if not self.connected:
            try:
                si = SmartConnectNoSSL(
                    host=self.vcenterHost, user=self.quser, pwd=self.qpasswd, port=443
                )
                self.eventManager = si.content.eventManager
                self.page_size = 1000
                self.connected = True
                self.elastic_info.add_ok_thread("Vsphere")
                return True
            except:
                print("Error connecting to Vsphere API on:", self.vcenterHost)
                self.connected = False
                self.elastic_info.add_problem_thread(
                    "Vsphere", Symptom.CONNECTION_ERROR
                )
        return self.connected

    # These routines are duplicates from Xtremio and should eventually be moved to a utility class
    def __get_time_from_file(self, filename):
        if os.path.isfile(filename):
            f = open(filename, "r")
            val = f.read()
            val = float(val)
            timeval = datetime.fromtimestamp(val)
        else:
            # If time file does not exist then start with last 4 weeks of data
            timeval = datetime.now() - timedelta(weeks=4)

        return timeval

    def __save_time_to_file(self, filename, savetime):
        f = open(filename, "w")
        f.write(str(time.time()))
        f.close

    def run(self):
        try:
            self.setName("Vsphere")
            self.query_data()
        except:
            traceback.print_exc()

    def query_data(self):
        while True:
            time.sleep(60)
            try:
                self.get_vsphere_data()
            except:
                print(
                    "Unable to query data from Vsphere API, will try again in 60 seconds"
                )
                traceback.print_exc()

    #
    # Method: process_tag - Private method process section of event returned from vsphere api
    # Parameters:
    #   value - tag(field) to examine
    #   outdoc - reference to document
    #   prefix - prefix to add to each field found when processing tag
    # Returns:
    #   None
    def process_tag(self, value, outdoc, prefix):

        attrib = {}
        if value is not None:
            vals = vars(value)
            for val in vals:
                if val == "dynamicProperty":
                    continue

                if val is not None:
                    if isinstance(vals[val], datetime):
                        attrib[val] = vals[val].isoformat()
                    else:
                        attrib[val] = str(vals[val])

            outdoc.set_value(prefix, attrib)

    #
    # Method: get_vsphere_data - Private method query data from vsphere using vSphere
    #                            Web Services API
    # Parameters:
    #   None
    # Returns:
    #   None
    def get_vsphere_data(self):

        if self.__connect():
            time_filter = vim.event.EventFilterSpec.ByTime()
            beginTime = self.__get_time_from_file(self.last_eventquery_file)
            if beginTime:
                time_filter.beginTime = beginTime

            curtime = time.time()
            time_filter.endTime = datetime.fromtimestamp(curtime)

            event_type_list = (
                []
            )  # Currently getting all events but have for filtering if needed
            filter_spec = vim.event.EventFilterSpec(
                eventTypeId=event_type_list, time=time_filter
            )

            try:
                event_collector = self.eventManager.CreateCollectorForEvents(
                    filter_spec
                )

                # Save query time so we don't requery same data
                self.__save_time_to_file(self.last_eventquery_file, curtime)
            except:
                self.connected = False

            # Process results
            while self.connected:
                # Note: If there's a huge number of events in the expected time range, this while loop will take a while.
                try:
                    events_in_page = event_collector.ReadNextEvents(self.page_size)
                except:
                    # print("get_vsphere_data: Exception on ReadNextEvents")
                    # traceback.print_exc()
                    continue

                # If no events then break now so empty document is not output
                if len(events_in_page) == 0:
                    break

                for event in events_in_page:
                    eventid = (type(event).__name__).split(".")[-1]

                    # Note: Events collected are not ordered by the event creation time,
                    # you might find the first event in the third page for example.

                    outdoc = Document(DocType.EVENT, DocSubtype.VSPHERE, None, None)
                    outdoc.set_value("eventid", eventid)
                    outdoc.set_value("userName", event.userName)

                    vals = vars(event)
                    for val in vals:
                        if val in self.tags:
                            self.process_tag(vals[val], outdoc, val)
                        elif val == "dynamicProperty":
                            continue
                        else:
                            if vals[val] is not None:
                                if isinstance(vals[val], datetime):
                                    outdoc.set_value(val, vals[val].isoformat())
                                else:
                                    item = vals[val]
                                    try:
                                        item = str(item)
                                    except:
                                        item = item.encode("utf-8")

                                    outdoc.set_value(val, item)

                        # print "val: ", val, ":", str(vals[val]), " type:", type(vals[val])

                        # outdoc.print_json()
                    self.outfile.output(outdoc)

            event_collector.DestroyCollector()


# Main class used for testing only
def main():

    vs = Vsphere()
    vs.start()
    print("Finished")


if __name__ == "__main__":
    main()
#################################################################################
#
#                                   Unclassified
#
#################################################################################
