# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class used to query data from Isilon storage devices. It
#          derives from the Device class and runs in it's own thread to
#          query health and status information from the Isilon device.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: Isilon.py
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
from Document import DocType, Health, License
from DeviceInfo import DeviceInfo
import threading


class Isilon(Device):
    # All Isilon Devices share the same output file so limit writing to one
    # Isilon Object at a time using a mutex
    outfile_mutex = threading.Lock()

    def __init__(self, devinfo):
        Device.__init__(self, devinfo.host, devinfo.devicetype, devinfo.hostname)

        self.cpu_stats = self.DeviceDoc("cpustats")
        self.status = {}
        self.drives = {}
        self.state = {}
        self.sensors = {}
        self.partitions = {}

        self.setup_rest(devinfo.user, devinfo.passwd, devinfo.port)

        self.license = self.DeviceDoc(DocType.LICENSE)
        self.licenses = list()
        self.usage = None
        self.health = self.DeviceDoc(DocType.HEALTH)
        self.health.set_url(devinfo.url)
        self.hardware = {}
        self.shares = list()
        self.exports = list()
        self.clients = list()
        self.temps = list()
        self.health.set_health(Health.UNKNOWN)
        self.partitions = list()
        self.node_info = {}

    def update_sensors(self, sensors, nodeid, lnn, query_time):

        # Loop through senors and pick out what we want
        for item in sensors["sensors"]:
            # print 'name:', item['name'],'type:',type(item)

            if item["count"] != 0:
                # print 'item:',item['name']
                if item["name"] == "Temps":
                    for val in item["values"]:
                        if (
                            "Margin" in val["desc"]
                            or "Mrgn" in val["desc"]
                            or "Mgn" in val["desc"]
                        ):
                            continue

                        entry = self.DeviceDoc(DocType.TEMP)
                        entry.add_description("Temperature information")
                        entry.set_value("node_id", nodeid)
                        entry.set_value("lnn", lnn)

                        entry.set_value("temp.sensor_name", val["desc"])
                        entry.set_value("temp.temp_value", val["value"])
                        entry.set_value("temp.units", val["units"])
                        entry.set_value("time", query_time)

                        self.temps.append(entry)

    def update_status(self, stats, nodeid, lnn, query_time):
        stat_entry = self.DeviceDoc(DocType.STATUS)
        stat_entry.add_description("Status information")
        stat_entry.set_value("node_id", nodeid)
        stat_entry.set_value("lnn", lnn)
        stat_entry.set_value("time", query_time)
        for item in stats:
            stat_entry.set_value(("status." + str(item)), stats[item])

        self.status[nodeid] = stat_entry

        # print stat_entry.toJSON()

    def update_hardware(self, hardware, nodeid, lnn, query_time):
        hw_entry = self.DeviceDoc(DocType.HARDWARE)
        hw_entry.add_description("Hardware information")
        hw_entry.set_value("node_id", nodeid)
        hw_entry.set_value("lnn", lnn)
        hw_entry.set_value("time", query_time)
        for item in hardware:
            # print "hw:", item ,'=', hardware[item]
            hw_entry.set_value(("hardware." + str(item)), hardware[item])

        # print hw_entry.toJSON()

        self.hardware[nodeid] = hw_entry

    def update_partitions(self, partitions, nodeid, lnn, query_time):
        for item in partitions["partitions"]:
            entry = self.DeviceDoc(DocType.PARTITION)
            entry.set_value("node_id", nodeid)
            entry.set_value("lnn", lnn)
            entry.set_value("partition", item)
            entry.set_value("time", query_time)

            # Translate percent_used from string into decimal for better useabilty in Elastic
            item["percent_used"] = float(item["percent_used"][:-1]) / 100
            # print entry.toJSON()

            self.partitions.append(entry)

    def update_cluster(self):
        # clear previous values
        del self.temps[:]
        self.temps = list()
        del self.partitions[:]
        self.partitions = list()
        self.hardware.clear()
        self.status.clear()

        self.node_info.clear()

        result = self.get_restdata("platform/3/cluster/nodes?devid=all")

        if (
            result.error == 0 and "nodes" in result.value.keys()
        ):  # Verify that nodes key exists
            #  [u'status', u'drives', u'hardware', u'state', u'lnn', u'sensors', u'id', u'partitions']
            for node in result.value["nodes"]:
                # print("node and keys")
                # print type(node), node.keys()
                nodeid = node["id"]
                lnn = node["lnn"]

                if not nodeid in self.node_info:
                    entry = self.DeviceDoc(DocType.NODE)
                    entry.add_description("Node Information")
                    entry.set_value("node_id", nodeid)
                    self.node_info[nodeid] = entry
                else:
                    entry = self.node_info[nodeid]

                entry.set_value("node.health", Health.UNKNOWN)
                entry.set_value("time", result.query_time)

                if "partitions" in node.keys():
                    self.update_partitions(
                        node["partitions"], nodeid, lnn, result.query_time
                    )
                if "status" in node.keys():
                    self.update_status(node["status"], nodeid, lnn, result.query_time)
                if "sensors" in node.keys():
                    self.update_sensors(node["sensors"], nodeid, lnn, result.query_time)
                if "hardware" in node.keys():
                    self.update_hardware(
                        node["hardware"], nodeid, lnn, result.query_time
                    )

    def __get_health_val(self, health):
        # "Health of the cluster or Node: 0 = Healthy, 1 = Attention, 2 = Down",
        healthval = Health.UNKNOWN
        if health == 0:
            healthval = Health.OK
        elif health == 1:
            healthval = Health.DEGRADED
        elif health == 2:
            healthval = Health.DOWN
        return healthval

    def test_access(self):
        retval = False
        result = self.get_restdata("platform/8/statistics/current?key=cluster.health")
        if result.error == 0:
            retval = True

        return retval

    def update_health(self):
        result = self.get_restdata(
            "platform/8/statistics/current?key=cluster.node.count.all&key=cluster.node.count.up&key=cluster.node.count.down&key=cluster.health&key=node.health&devid=all"
        )
        # Verify that stats key exists
        if result.error == 0 and "stats" in result.value.keys():
            for item in result.value["stats"]:
                if item["key"] == "node.health":
                    name = "node." + str(item["devid"]) + "." + str(item["key"])
                    self.health.set_value(name, self.__get_health_val(item["value"]))
                elif item["key"] == "cluster.health":
                    health = item["value"]
                    self.health.set_health(self.__get_health_val(health))
                else:
                    self.health.set_value(item["key"], item["value"])

            self.health.set_license(self.license_status)
            # print self.health.toJSON()
        else:
            self.health.set_health(Health.UNKNOWN)

        self.health.set_value("time", result.query_time)

    def update_usage(self):
        result = self.get_restdata(
            "platform/8/statistics/current?key=ifs.bytes.total&key=ifs.bytes.used&key=ifs.bytes.free&=ifs.bytes.avail&key=ifs.percent.used&key=ifs.percent.free&key=ifs.percent.avail&devid=all"
        )

        if (
            result.error == 0 and "stats" in result.value.keys()
        ):  # Verify that stats key exists
            self.usage = self.DeviceDoc(DocType.CAPACITY)
            self.usage.add_description("Usage Information")
            for item in result.value["stats"]:
                self.usage.set_value(item[u"key"], item[u"value"])

                # print ("item:", item)
                # print item[u'key'], "=", item[u'value']
                for k, v in item.items():
                    key = k.encode("ascii")
                    # print("key:",key, "   Value:", v)
            # print item
            self.usage.set_value("time", item[u"time"])
        else:
            self.usage = None

    def update_node(self):
        result = self.get_restdata(
            "platform/8/statistics/current?key=node.ifs.bytes.free&key=node.ifs.bytes.used&key=node.ifs.bytes.total&key=node.ifs.ssd.bytes.free&key=node.ifs.ssd.bytes.used&key=node.ifs.ssd.bytes.total&key=node.ifs.bytes.deleted&key=node.ifs.bytes.in&key=node.ifs.bytes.out&key=node.ifs.bytes.deleted.rate&key=node.ifs.bytes.in.rate&key=node.ifs.bytes.out.rate&key=node.ifs.bytes.in.rate.max&key=node.ifs.bytes.out.rate.max&key=node.ifs.files.created&key=node.ifs.files.removed&key=node.ifs.num.lookups&key=node.ifs.files.created.rate&key=node.ifs.files.removed.rate&key=node.ifs.num.lookups.rate&key=node.ifs.ops.in&key=node.ifs.ops.out&key=node.ifs.ops.in.rate&key=node.ifs.ops.out.rate&key=node.cpu.count&key=node.cpu.idle.avg&key=node.cpu.intr.avg&key=node.cpu.nice.avg&key=node.cpu.user.avg&key=node.cpu.sys.avg&key=node.cpu.idle.max&key=node.cpu.intr.max&key=node.cpu.nice.max&key=node.cpu.user.max&key=node.cpu.sys.max&key=node.cpu.throttling&key=node.load.1min&key=node.load.5min&key=node.load.15min&key=node.memory.used&key=node.memory.free&key=node.open.files&key=node.process.count&key=node.uptime&key=node.boottime&key=node.diskless&key=node.disk.count&key=node.disk.unhealthy.count&key=node.health&key=node.clientstats.connected.nfs&key=node.clientstats.connected.cifs&devid=all"
        )

        if (
            result.error == 0 and "stats" in result.value.keys()
        ):  # Verify that stats key exists
            for item in result.value["stats"]:
                nodeid = item["devid"]
                if not nodeid in self.node_info:
                    entry = self.DeviceDoc(DocType.NODE)
                    entry.add_description("Node Information")
                    entry.set_value("node_id", nodeid)
                    self.node_info[nodeid] = entry
                else:
                    entry = self.node_info[nodeid]

                newkey = item["key"]
                # Fix issue where some ifs fields have nested values of an object
                #  ex:  byte.in and bytes.in.rate - we can't have an a concret value
                #       in bytes.in if we want to use it as an object in Elastic so
                #       we replace all "." with "_" so there sub values are not part
                #       of an object
                if newkey[:9] == "node.ifs.":
                    newkey = newkey[:9] + newkey[9:].replace(".", "_")

                if newkey == "node.health":
                    entry.set_value(newkey, self.__get_health_val(item["value"]))
                    entry.set_value("time", result.query_time)
                elif newkey.split(".")[1] == "cpu":
                    endkey = newkey.split(".")[-1]
                    try:
                        if endkey == "max" or endkey == "avg":
                            entry.set_value(newkey, float(item["value"]) / 1000)
                        else:
                            entry.set_value(newkey, item["value"])
                    except:
                        print(
                            "Node id: ",
                            nodeid,
                            " unable to set cpu value for item:",
                            item["key"],
                            " value: ",
                            item["value"],
                        )
                elif newkey.split(".")[1] == "load":
                    try:
                        entry.set_value(newkey, float(item["value"]) / 10000)
                    except:
                        print(
                            "Node id:",
                            nodeid,
                            " unable to set load value for item:",
                            item["key"],
                            " value: ",
                            item["value"],
                        )
                else:
                    entry.set_value(newkey, item["value"])

            for key in self.node_info:
                # Calculate percent used for ifs
                try:
                    total = float(self.node_info[key].get_value("node.ifs.bytes_total"))
                    usedpct = float(0.0)
                    if total > 0:
                        usedpct = (
                            float(self.node_info[key].get_value("node.ifs.bytes_used"))
                            / total
                        )
                        usedpct = round(usedpct, 4)
                    self.node_info[key].set_value("node.ifs.bytes_used_pct", usedpct)
                except:
                    print(
                        "Node id:",
                        key,
                        " unable to calculate percent used for ssd, ssd_bytes_total :",
                        self.node_info[key].get_value("node.ifs.ssd_bytes_total"),
                        " ssd_bytes_used: ",
                        self.node_info[key].get_value("node.ifs.ssd_bytes_used"),
                    )

                # Calculate percent used for ssd
                try:
                    total = float(
                        self.node_info[key].get_value("node.ifs.ssd_bytes_total")
                    )
                    usedpct = float(0.0)
                    if total > 0:
                        usedpct = (
                            float(
                                self.node_info[key].get_value("node.ifs.ssd_bytes_used")
                            )
                            / total
                        )
                        usedpct = round(usedpct, 4)
                    self.node_info[key].set_value(
                        "node.ifs.ssd.bytes_used_pct", usedpct
                    )
                except:
                    print(
                        "Node id:",
                        key,
                        " unable to calculate percent used for ssd, ssd_bytes_total :",
                        self.node_info[key].get_value("node.ifs.ssd_bytes_total"),
                        " ssd_bytes_used: ",
                        self.node_info[key].get_value("node.ifs.ssd_bytes_used"),
                    )

            # 	print 'node_info(', key, ')=', self.node_info[key].toJSON()

    def update_shares(self):
        result = self.get_restdata("platform/8/protocols/smb/shares")

        del self.shares[:]
        self.shares = list()
        if (
            result.error == 0 and "shares" in result.value.keys()
        ):  # Verify that shares key exists
            shares = result.value["shares"]
            for share in shares:
                share_entry = self.DeviceDoc(DocType.SHARE)
                share_entry.add_description("Isilon Share")
                share_entry.set_value("time", result.query_time)
                for item in share:
                    share_entry.set_value(("share." + str(item)), share[item])

                # print share_entry.toJSON()
                self.shares.append(share_entry)

    def update_exports(self):
        result = self.get_restdata("platform/8/protocols/nfs/exports")

        del self.exports[:]
        self.exports = list()
        if (
            result.error == 0 and "exports" in result.value.keys()
        ):  # Verify that shares key exists
            exports = result.value["exports"]
            for export in exports:
                export_entry = self.DeviceDoc(DocType.EXPORT)
                export_entry.add_description("Isilon Export")
                export_entry.set_value("time", result.query_time)
                for item in export:
                    export_entry.set_value(("export." + str(item)), export[item])

                # print export_entry.toJSON()
                self.exports.append(export_entry)

    def update_clientsummary(self):
        result = self.get_restdata("platform/8/statistics/summary/client")
        del self.clients[:]
        self.clients = list()
        if (
            result.error == 0 and "client" in result.value.keys()
        ):  # Verify that clients key exists
            clients = result.value["client"]
            for client in clients:
                entry = self.DeviceDoc("client_summary")
                entry.add_description("Isilon Client Summary")
                entry.set_value("client", client)
                if not self.isIP(client["local_addr"]):
                    del client["local_addr"]
                if not self.isIP(client["remote_addr"]):
                    del client["remote_addr"]

                entry.set_value("node_id", client["node"])
                entry.set_value("time", result.query_time)
                self.clients.append(entry)

        # print "Clients found:"
        # for c in self.clients:
        # 	print c.toJSON()

    def update_licenses(self):
        result = self.get_restdata("platform/8/license/licenses")

        self.license_status = License.UNKNOWN
        del self.licenses[:]
        self.licenses = list()
        if (
            result.error == 0 and "licenses" in result.value.keys()
        ):  # Verify that license key exists
            self.license_status = License.OK
            self.license.set_value("license", result.value)
            self.license.set_value("time", result.query_time)

            # If signature is not valid then license is INVALID
            if result.value["valid_signature"] != True:
                self.license_status = License.INVALID
            else:
                licenses = result.value["licenses"]
                swid = result.value["swid"]

                for license in licenses:
                    entry = self.DeviceDoc(DocType.LICENSE)
                    entry.set_value("licenseid", swid)
                    entry.set_value("license", license)
                    entry.add_description("License Information")
                    self.licenses.append(entry)

                    # print ("expiring_alert:", license['expiring_alert'])
                    if license["expired_alert"] == True:
                        self.license_status = License.EXPIRED
                    elif (
                        license["expiring_alert"] == True
                        and self.license_status != License.EXPIRED
                    ):
                        self.license_status = License.EXPIRING
                    #
                    # Check Status, valid values are: platform/8/license/licenses?describe
                    # 	"enum": [ "Unlicensed", "Licensed", "Expired", "Evaluation", "Evaluation Expired" ]
                    elif "expired" in license["status"].lower():
                        self.license_status = License.EXPIRED

    #
    # Method: output_data - output current data to file
    #
    def output_data(self):
        Isilon.outfile_mutex.acquire()
        self.output(self.node_info)
        self.output(self.licenses)
        self.output(self.partitions)
        self.output(self.shares)
        self.output(self.exports)
        self.output(self.temps)
        self.output(self.hardware)
        self.output(self.status)
        self.output(self.usage)
        self.output(self.clients)
        self.output(self.health)
        Isilon.outfile_mutex.release()

    def work(self):
        count = 0

        while self.dowork:
            self.update_licenses()  # Must come before Health
            self.update_health()
            self.update_shares()
            self.update_exports()

            self.update_cluster()  # Must come before node
            self.update_node()
            self.update_usage()

            if count % 5 == 0:
                self.update_clientsummary()
            count = count + 1

            self.output_data()
            time.sleep(constants.ISILON_SLEEP)


#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
