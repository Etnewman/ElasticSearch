# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class used to query data from XtreamIO storage devices. It
#          derives from the Device class and runs in it's own thread to
#          query health and status information from the XtreamIO device.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: CiscoSwitch.py
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
# Frequency: Runs as a thread in the elasticDataCollector Service
#
# Information Security Authorization
# ACC/A26 IA Approval: year-mm-dd, Name, ACC ISSE
#
# Lead System Engineering Authorization
# AF-DCGS LSE Approval: year-mm-dd, Name, AF-DCGS/AO
#
###########################################################################
#
import constants
import json
import time
from Device import Device, DeviceType
from Document import DocType, Health
from DeviceInfo import DeviceInfo, SNMPDeviceInfo
import os.path
import datetime
import threading


class Xtremio(Device):
    # All Xtremio Devices share the same output file so limit writing to one
    # Xtremio Object at a time using a mutex
    outfile_mutex = threading.Lock()

    def __init__(self, devinfo):
        Device.__init__(self, devinfo.host, devinfo.devicetype, devinfo.hostname)

        self.cpu_stats = self.DeviceDoc("cpustats")
        self.setup_rest(devinfo.user, devinfo.passwd, devinfo.port)

        self.last_eventquery_file = constants.XTREMIO_LAST_EVENT_QUERY
        self.url = devinfo.url
        self.health = list()  # Health of each cluster
        self.volumes = list()
        self.daes = list()
        self.clusters = list()
        self.events = list()

    def __get_time_from_file(self, filename):
        if os.path.isfile(filename):
            # print "File exists"
            f = open(filename, "r")
            val = f.read()
            val = float(val)
            timeval = time.strftime(
                "?from-date-time=%Y-%m-%d%%20%H%%3A%M%%3A%S", time.localtime(val)
            )
            # print timeval
        else:
            timeval = ""

        return timeval

    def __save_time_to_file(self, filename):
        f = open(filename, "w")
        f.write(str(time.time()))
        f.close

    def test_access(self):
        retval = False
        result = self.get_restdata(
            "api/json/v2/types/clusters?full=1&prop=total-memory-in-use-in-percent"
        )
        if result.error == 0:
            retval = True

        return retval

    def update_clusters(self):

        result = self.get_restdata(
            "api/json/v2/types/clusters?full=1&prop=total-memory-in-use-in-percent&prop=last-upgrade-attempt-version&prop=free-ud-ssd-space-level&prop=shared-memory-in-use-recoverable-ratio-level&prop=num-of-nodes&prop=max-snapshots-per-volume&prop=compression-factor&prop=device-connectivity-mode&prop=hardware-platform&prop=num-of-vols&prop=iops&prop=wr-iops-by-block&prop=max-mappings&prop=num-of-tars&prop=name&prop=acc-num-of-unaligned-wr&prop=sys-sw-version&prop=fc-port-speed&prop=index&prop=upgrade-failure-reason&prop=num-of-xenvs&prop=num-of-ssds&prop=sys-health-state&prop=bw&prop=send-snmp-heartbeat&prop=installation-type&prop=avg-latency&prop=total-memory-in-use&prop=ud-ssd-space-in-use&prop=num-of-jbods&prop=license-id&prop=data-reduction-ratio-text&prop=wr-bw&prop=wr-latency&prop=unaligned-rd-bw&prop=max-cgs&prop=rd-bw-by-block&prop=ud-ssd-space&prop=max-snapshots-per-vol&prop=guid&prop=useful-ssd-space-per-ssd&prop=acc-num-of-rd&prop=data-reduction-ratio&prop=ssd-very-high-utilization-thld-crossing&prop=acc-size-of-wr&prop=shared-memory-in-use-ratio-level&prop=num-of-internal-vols&prop=under-maintenance&prop=ssd-high-utilization-thld-crossing&prop=psnt-part-number&prop=sys-mgr-conn-state&prop=max-mapped-volumes&prop=size-and-capacity&prop=upgrade-state&prop=sys-activation-timestamp&prop=brick-list&prop=small-rd-bw&prop=max-igs&prop=space-saving-ratio&prop=compression-mode&prop=vaai-tp-limit-crossing&prop=small-wr-iops&prop=sys-index&prop=logical-space-in-use&prop=max-volumes&prop=sys-psnt-serial-number&prop=encryption-mode&prop=last-upgrade-attempt-timestamp&prop=thin-provisioning-ratio&prop=sys-mgr-conn-error-reason&prop=firmware-upgrade-failure-reason&prop=num-of-upses&prop=num-of-major-alerts&prop=naa-sys-id&prop=unaligned-iops&prop=unaligned-bw&prop=encryption-supported&prop=small-rd-iop&prop=replication-efficiency-ratio&prop=vol-size&prop=unaligned-wr-bw&prop=thin-provisioning-savings&prop=dedup-space-in-use&prop=num-of-bricks&prop=rd-latency&prop=max-num-of-ssds-per-rg&prop=iops-by-block&prop=sys-state&prop=consistency-state&prop=num-of-critical-alerts&prop=rd-iops&prop=max-vol-per-cg&prop=free-ud-ssd-space-in-percent"
        )

        # Clear list
        del self.clusters[:]
        self.clusters = list()

        if (
            result.error == 0 and "clusters" in result.value.keys()
        ):  # Verify that volumes key exists
            clusters = result.value["clusters"]
            del self.health[:]
            self.health = list()
            for cluster in clusters:
                for tag in cluster["brick-list"]:
                    for i in range(len(tag)):
                        if isinstance(tag[i], (int)):
                            tag[i] = str(tag[i])

                entry = self.DeviceDoc("cluster")
                entry.add_description("Cluster Information")
                entry.set_value("time", result.query_time)
                entry.set_url(self.url)

                # Size values are returned from the Xtremio in KBytes.  Convert them to Bytes
                # to allow Kibana to use Bytes Process for displaying
                cluster["free-ud-ssd-space-in-percent"] = (
                    float(cluster["free-ud-ssd-space-in-percent"]) / 100
                )
                cluster["total-memory-in-use-in-percent"] = (
                    float(cluster["total-memory-in-use-in-percent"]) / 100
                )
                cluster["ud-ssd-space-in-use"] = (
                    int(cluster["ud-ssd-space-in-use"]) * 1024
                )
                cluster["ud-ssd-space"] = int(cluster["ud-ssd-space"]) * 1024
                cluster["logical-space-in-use"] = (
                    int(cluster["logical-space-in-use"]) * 1024
                )
                cluster["useful-ssd-space-per-ssd"] = (
                    int(cluster["useful-ssd-space-per-ssd"]) * 1024
                )
                cluster["logical-space-in-use"] = (
                    int(cluster["logical-space-in-use"]) * 1024
                )
                cluster["vol-size"] = int(cluster["vol-size"]) * 1024
                cluster["dedup-space-in-use"] = (
                    int(cluster["dedup-space-in-use"]) * 1024
                )

                entry.set_value("cluster", cluster)
                self.clusters.append(entry)

                # Update Health Doc for Cluster
                entry = self.DeviceDoc(DocType.HEALTH)
                entry.set_value("time", time.time())
                entry.add_description("Overall Health")
                entry.set_url(self.url)
                entry.set_value("cluster.name", cluster["name"])
                entry.set_value("cluster.sys-state", cluster["sys-state"])
                entry.set_value("cluster.sys-health-state", cluster["sys-health-state"])
                entry.set_value(
                    "cluster.sys-mgr-conn-state", cluster["sys-mgr-conn-state"]
                )
                if (
                    cluster["sys-mgr-conn-state"] == "connected"
                    and cluster["sys-state"] == "active"
                ):
                    entry.set_health(Health.OK)
                else:
                    entry.set_health(Health.DEGRADED)

                self.health.append(entry)
        else:
            # If we are unable to talk to the device then we should mark it as unknown
            # If we don't have any health documents yet then create a general one
            if len(self.health) == 0:
                entry = self.DeviceDoc(DocType.HEALTH)
                entry.set_value("time", time.time())
                entry.set_url(self.url)
                entry.add_description("Overall Health")
                entry.set_health(Health.UNKNOWN)
                self.health.append(entry)
            else:
                # Mark any of the clusters we know about as Unknown
                for entry in self.health:
                    entry.set_health(Health.UNKNOWN)
                    entry.set_value("time", time.time())

    # Disk Array Enclosures
    def update_daes(self):
        result = self.get_restdata(
            "api/json/v2/types/daes?full=1&prop=temperature-state&prop=fru-lifecycle-state&prop=fan-pair4-status&prop=obj-severity&prop=voltage-over-populated&prop=num-of-jbod-psus&prop=sys-index&prop=serial-number&prop=fan-pair2-status&prop=fan-pair2-hardware-label&prop=jbod-index&prop=fru-replace-failure-reason&prop=guid&prop=index&prop=fan-1-rpm&prop=fan-8-rpm&prop=jbod-name&prop=num-of-jbod-controllers&prop=voltage-line&prop=fan-2-rpm&prop=fan-5-rpm&prop=brick-name&prop=hw-revision&prop=jbod-id&prop=xms-id&prop=fan-4-rpm&prop=fan-pair1-hardware-label&prop=identify-led&prop=fw-version&prop=sys-name&prop=fan-7-rpm&prop=part-number&prop=brick-index&prop=fan-pair4-hardware-label&prop=sys-id&prop=fan-pair1-status&prop=name&prop=brick-id&prop=fan-6-rpm&prop=status-led&prop=fan-3-rpm&prop=href&prop=fan-pair3-status&prop=model-name&prop=fan-pair3-hardware-label"
        )

        # Clear list
        del self.daes[:]
        self.daes = list()

        if (
            result.error == 0 and "daes" in result.value.keys()
        ):  # Verify that daes key exists
            daes = result.value["daes"]
            # Fix any items in lists that should be strings
            for dae in daes:
                for x in dae:
                    # print dae[x], "TYPE:", type(dae[x])
                    if isinstance(dae[x], (list)):
                        l = dae[x]
                        for i in range(len(l)):
                            if isinstance(l[i], (int)):
                                l[i] = str(l[i])

                entry = self.DeviceDoc("dae")
                entry.add_description("DAE Information")
                entry.set_value("time", result.query_time)
                entry.set_value("cluster.name", dae["sys-name"])
                entry.set_value("dae", dae)

                # print entry.toJSON()
                self.daes.append(entry)

    def update_volumes(self):
        result = self.get_restdata(
            "api/json/v2/types/volumes?full=1&prop=name&prop=iops&prop=sys-name&prop=application-type&prop=logical-space-in-use&prop=vol-size&prop=tag-list"
        )

        # Clear list
        del self.volumes[:]
        self.volumes = list()

        if (
            result.error == 0 and "volumes" in result.value.keys()
        ):  # Verify that volumes key exists
            vols = result.value["volumes"]
            for volume in vols:
                for tag in volume["tag-list"]:
                    for i in range(len(tag)):
                        if isinstance(tag[i], (int)):
                            tag[i] = str(tag[i])

                entry = self.DeviceDoc("volume")
                entry.add_description("Volume Information")
                entry.set_value("time", result.query_time)
                entry.set_value("volume", volume)
                entry.set_value("cluster.name", volume["sys-name"])
                volume["vol-size"] = int(volume["vol-size"]) * 1024
                volume["logical-space-in-use"] = (
                    int(volume["logical-space-in-use"]) * 1024
                )
                self.volumes.append(entry)

                # print "entry", entry.toJSON()

    def __convert_stringtime(self, timestr):
        epoch = datetime.datetime(1970, 1, 1)
        myformat = "%Y-%m-%d %H:%M:%S.%f"
        mydt = datetime.datetime.strptime(timestr, myformat)
        val = (mydt - epoch).total_seconds()

        newdate = str("%.6f" % val)
        return val

    def update_events(self):

        result = self.get_restdata(
            "/api/json/v2/types/events"
            + self.__get_time_from_file(self.last_eventquery_file)
        )
        self.__save_time_to_file(self.last_eventquery_file)

        # print json.dumps(result.value, sort_keys=True, indent=4, default=lambda o: o.__dict__)

        del self.events[:]
        self.events = list()

        if (
            result.error == 0 and "events" in result.value.keys()
        ):  # Verify that volumes key exists
            events = result.value["events"]
            for event in events:
                entry = self.DeviceDoc(DocType.EVENT)
                entry.add_description("XtremIO Event Information")
                entry.set_value("time", event["timestamp"])
                clust = event["cluster"]
                if clust:
                    entry.set_value("cluster.name", clust.split(" ", 1)[0])
                entry.set_value("event", event)
                self.events.append(entry)

            # for event in self.events:
            # 	print event.toJSON()

    #
    # Method: output_data - output current data to file
    #
    def output_data(self):
        Xtremio.outfile_mutex.acquire()
        self.output(self.daes)
        self.output(self.clusters)
        self.output(self.health)
        self.output(self.volumes)
        self.output(self.events)
        Xtremio.outfile_mutex.release()

    #
    # Method: work - work
    #
    def work(self):
        while self.dowork:
            self.update_daes()
            self.update_clusters()
            self.update_volumes()
            self.update_events()

            self.output_data()
            time.sleep(constants.XTREMEIO_SLEEP)


def main():

    xtremio = DeviceInfo()
    xtremio.setup(
        "u00av01xms1",
        443,
        DeviceType.XTREMIO,
        "00_elastic.svc",
        "5ty6%TY^6yu7^YU&",
        "ech-xtremio",
        "https://u00av01xms1",
    )

    xt = Xtremio(xtremio)
    xt.start()
    # Monitor all threads from main and if any exit unexpectedly log error
    xt.join()
    print("Finished")


if __name__ == "__main__":
    main()
#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
