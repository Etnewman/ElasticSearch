# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class used to query data from Dell Idrac Devices.  It
#          derives from the Device class and runs in it's own thread to
#          query health and status information from Idrac Devices.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: DellIdrac.py
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
import pprint
import binascii
from Device import Device
from Document import DocType, Health, Symptom
import threading
import copy


class DellIdrac(Device):
    # All DellIdrac Devices share the same output file so limit writing to one
    # DellIdrac Object at a time using a mutex
    outfile_mutex = threading.Lock()

    #
    # Constructor
    #
    def __init__(self, devinfo):
        Device.__init__(self, devinfo.host, devinfo.devicetype, devinfo.hostname)
        self.setup_snmp(devinfo.user, devinfo.passwd, devinfo.privPass, devinfo.timeout)

        self.ent_physical_desc = {}
        self.fan_info = {}
        self.power_info = {}
        self.disk_info = {}
        self.vdisk_info = {}
        self.chassis_power_info = {}
        self.chassis_info = {}
        self.interfaces = {}
        self.health = self.DeviceDoc(DocType.HEALTH)
        self.health.set_health(Health.UNKNOWN)
        self.health.set_url("Not Defined")
        self.health.set_servicetag("Not Defined")
        self.temps = {}
        self.fqdn = "Unknown"

    def __goodResult(self, result):
        retval = True
        if result.error != 0:
            self.health.add_health_symptom(Symptom.REQUEST_ERROR)
            retval = False

        return retval

    #
    # Method: update_health - Update overall health of device
    #
    def update_health(self):
        self.health.set_health(Health.UNKNOWN)
        self.health.set_value("time", time.time())
        self.health.add_description("Overall Health")

        #
        # 5.2 Defines the overall health status being monitored
        #
        health = self.get_pysnmpdata("IDRAC-MIB-SMIv2", "statusGroup")
        # OID = 1.3.6.1.4.1.674.10892.5.2
        if self.__goodResult(health):
            # Init var in case of missing mib response
            var = None
            for var in health.value:
                if not (var.val == "N/A" or var.val == "notApplicable"):
                    if var.tag == "globalSystemStatus":
                        if var.val == "ok":
                            healthval = Health.OK
                        else:
                            healthval = Health.DEGRADED

                        self.health.set_health(healthval)

                    if var.val != "ok":
                        if var.tag == "systemLCDStatus":
                            self.health.add_health_symptom(Symptom.SYSTEMLCDSTATUS)
                        elif var.tag == "globalStorageStatus":
                            self.health.add_health_symptom(Symptom.GLOBALSTORAGESTATUS)

                    if var.val == "off" and var.tag == "systemPowerState":
                        self.health.add_health_symptom(Symptom.SYSTEMPOWERSTATE)

                    self.health.set_value(var.tag, var.val)

            if len(self.health.get_health_symptoms()) == 0:
                self.health.add_health_symptom(Symptom.NONE)

            # Check to make sure var is missing
            if var is not None:
                self.health.set_value(var.tag, var.val)

        #
        # Add more information to health document (OS, service tag, etc)
        #
        health = self.get_pysnmpdata("IDRAC-MIB-SMIv2", "informationGroup")
        # OID = 1.3.6.1.4.1.674.10892.5.1
        if self.__goodResult(health):
            for var in health.value:
                if var.tag == "racURL":
                    urlval = var.val
                    self.health.set_url(urlval)

                if var.tag == "systemServiceTag":
                    servicetag = var.val
                    self.health.set_servicetag(servicetag)

                self.health.set_value(var.tag, var.val)
                self.health.set_value("time", time.time())
                self.health.add_description("Overall Health")

            self.fqdn = self.health.get_value("systemFQDN")

    #
    # Method: update_fans - retrieve and update fan status
    #
    def update_fans(self):
        #
        # 700.12.1 Defines the overall fan status
        fan_info = self.get_pysnmpdata("IDRAC-MIB-SMIv2", "coolingDeviceTableEntry")
        # OID = 1.3.6.1.4.1.674.10892.5.4.700.12.1
        if self.__goodResult(fan_info):
            for var in fan_info.value:
                if not var.iid in self.fan_info:
                    entry = self.DeviceDoc(DocType.FAN)
                    self.fan_info[var.iid] = entry
                    entry.add_description("Overall FAN Entry")
                else:
                    entry = self.fan_info[var.iid]

                entry.set_value(var.tag, var.val)

                if var.tag == "coolingDeviceStateSettings":
                    entry.set_value("time", fan_info.query_time)
                    entry.set_value("systemFQDN", self.fqdn)

                elif var.tag == ("coolingDeviceStatus") and var.val != "ok":
                    self.health.add_health_symptom(Symptom.FAN)

    #
    # Method: update_temps - retrieve and update temperature status
    #
    def update_temps(self):
        #
        # 10.1.24 Defines the overall temperature status
        temps = self.get_pysnmpdata(
            "IDRAC-MIB-SMIv2", "systemStateTemperatureStatusCombined"
        )
        # OID = 1.3.6.1.4.1.674.10892.5.4.200.10.1.24
        if self.__goodResult(temps):
            for var in temps.value:
                if not var.iid in self.temps:
                    entry = self.DeviceDoc(DocType.TEMP)
                    self.temps[var.iid] = entry
                    entry.add_description("Overall Temperature Entry")
                else:
                    entry = self.temps[var.iid]

                entry.set_value(var.tag, var.val)

                if var.tag == "systemStateTemperatureStatusCombined":
                    entry.set_value("time", temps.query_time)
                    entry.set_value("systemFQDN", self.fqdn)

    #
    # Method: update_power - retrieve and update power supply information
    #
    def update_power(self):
        #
        # 3.1.5 Defines the overall power status
        power_info = self.get_pysnmpdata("IDRAC-MIB-SMIv2", "powerSupplyTableEntry")
        # OID = 1.3.6.1.4.1.674.10892.5.4.600.12.1
        if self.__goodResult(power_info):
            for var in power_info.value:
                if not var.iid in self.power_info:
                    entry = self.DeviceDoc(DocType.POWER)
                    self.power_info[var.iid] = entry
                    entry.add_description("Overall Power Entry")
                else:
                    entry = self.power_info[var.iid]

                entry.set_value(var.tag, var.val)
                #  To only add the query time once we check for a unique tag for each entry
                if var.tag == "powerSupplyStatus":
                    entry.set_value("time", power_info.query_time)
                    entry.set_value("systemFQDN", self.fqdn)

    #
    # Method: update_interfaces - retrieve and update interface information
    #
    def update_interfaces(self):
        # Query interface data
        intfc = self.get_pysnmpdata("IF-MIB", "ifEntry")
        # OID = 1.3.6.1.2.1.2.2.1
        timedelta = {}

        # Loop through returned values and create a Document for each interface returned.
        if self.__goodResult(intfc):
            for var in intfc.value:
                if not var.iid in self.interfaces:
                    entry = self.DeviceDoc(DocType.INTERFACE)
                    self.interfaces[var.iid] = entry
                else:
                    entry = self.interfaces[var.iid]
                    if not var.iid in timedelta:
                        if entry.get_value("time") != "Attribute does not exist":
                            timedelta[var.iid] = intfc.query_time - entry.get_value(
                                "time"
                            )

                #
                # Let calculate interface utilization using this queries values
                # against last queries values
                if var.tag == "ifInOctets":
                    currVal = entry.get_value(var.tag)
                    if currVal != "Attribute does not exist":
                        speed = int(entry.get_value("ifSpeed"))
                        if speed != 0:
                            diff = int(var.val) - int(currVal)
                            utilization = (diff * 8 * 100) / (
                                timedelta[var.iid] * speed
                            )
                            utilization = round(utilization, 4)

                            # Uncomment for debugging
                            # print 'Interface id:', var.iid, ' Diff = ', diff, ' timedelta:', timedelta[var.iid],' ifSpeed:',speed, ' Utilization: ', utilization

                            entry.set_value("inputUtilization", utilization)

                elif var.tag == "ifOutOctets":
                    currVal = entry.get_value(var.tag)
                    if currVal != "Attribute does not exist":
                        speed = int(entry.get_value("ifSpeed"))
                        if speed != 0:
                            diff = int(var.val) - int(currVal)
                            utilization = (diff * 8 * 100) / (
                                timedelta[var.iid] * speed
                            )
                            utilization = round(utilization, 4)

                            # Uncomment for debugging
                            # print 'Interface id:', var.iid, ' Diff = ', diff, ' timedelta:', timedelta[var.iid],' ifSpeed:',speed, ' Utilization: ', utilization

                            entry.set_value("outputUtilization", utilization)

                # Set the new value in the document
                entry.set_value(var.tag, var.val)
                if var.tag == "ifIndex":
                    entry.set_value("time", intfc.query_time)
                    entry.set_value("systemFQDN", self.fqdn)
                elif var.tag == "ifType":
                    entry.add_description(var.val)

            # Uncomment for debugging
            # for key in self.interfaces:
            # print 'interface(', key, ')=', self.interfaces[key].print_all(), '\n'

    #
    # Method: chassis_info - retrieve chassis information
    #
    def update_chassis(self):
        #
        # 5.5.1.20.130.3.1 Defines the overall chassis status
        chassis_info = self.get_pysnmpdata("IDRAC-MIB-SMIv2", "enclosureTableEntry")
        # OID = 1.3.6.1.4.1.674.10892.5.5.1.20.130.3.1
        if self.__goodResult(chassis_info):
            for var in chassis_info.value:
                if not var.val == "Not Applicable":
                    if not var.iid in self.chassis_info:
                        entry = self.DeviceDoc(DocType.STATS)
                        self.chassis_info[var.iid] = entry
                        entry.add_description("Overall Chassis Entry")
                    else:
                        entry = self.chassis_info[var.iid]

                    entry.set_value(var.tag, var.val)
                    #  To only add the query time once we check for a unique tag for each entry
                    if var.tag == "enclosureNumber":
                        entry.set_value("time", chassis_info.query_time)
                        entry.set_value("systemFQDN", self.fqdn)

    #
    # Method: physical_disk - retrieve and physical disk information
    #
    def update_disk(self):
        #
        # 5.5.1.20.130.4.1 Defines the overall physical disk status
        disk_info = self.get_pysnmpdata("IDRAC-MIB-SMIv2", "physicalDiskTableEntry")
        # OID = 1.3.6.1.4.1.674.10892.5.5.1.20.130.4.1
        if self.__goodResult(disk_info):
            for var in disk_info.value:
                if not var.iid in self.disk_info:
                    entry = self.DeviceDoc(DocType.DISK)
                    self.disk_info[var.iid] = entry
                    entry.add_description("Overall Physical Disk Entry")
                else:
                    entry = self.disk_info[var.iid]

                entry.set_value(var.tag, var.val)
                #  To only add the query time once we check for a unique tag for each entry
                if var.tag == "physicalDiskNumber":
                    entry.set_value("time", disk_info.query_time)
                    entry.set_value("systemFQDN", self.fqdn)

    #
    # Method: update_vdisk - retrieve and physical disk information
    #
    def update_vdisk(self):
        #
        # 140.1.1 Defines the overall virtual disk status
        vdisk_info = self.get_pysnmpdata("IDRAC-MIB-SMIv2", "virtualDiskTableEntry")
        # OID = 1.3.6.1.4.1.674.10892.5.5.1.20.140.1.1
        if self.__goodResult(vdisk_info):
            for var in vdisk_info.value:
                if not var.iid in self.vdisk_info:
                    entry = self.DeviceDoc(DocType.DISK)
                    self.vdisk_info[var.iid] = entry
                    entry.add_description("Overall Virtual Disk Entry")
                    entry.add_subtype("Virtual Disk")
                else:
                    entry = self.vdisk_info[var.iid]

                if var.tag == "virtualDiskName":
                    entry.set_value(var.tag, repr(var.val))
                else:
                    entry.set_value(var.tag, var.val)
                #  To only add the query time once we check for a unique tag for each entry
                if var.tag == "VirtualDiskNumber":
                    entry.set_value("time", vdisk_info.query_time)
                    entry.set_value("systemFQDN", self.fqdn)

    #
    # Method: output_data - output current data to file
    #
    def output_data(self):
        DellIdrac.outfile_mutex.acquire()
        self.output(self.disk_info)
        self.output(self.vdisk_info)
        self.output(self.chassis_info)
        self.output(self.fan_info)
        self.output(self.temps)
        self.output(self.interfaces)
        self.output(self.power_info)
        self.output(self.health)
        DellIdrac.outfile_mutex.release()

    #
    # Method: work - main work loop for thread
    #
    def work(self):

        while self.dowork:
            # Clear symptoms for next checkup
            self.health.clear_health_symptoms()

            self.update_fans()
            self.update_temps()
            self.update_disk()
            self.update_vdisk()
            self.update_chassis()
            self.update_interfaces()
            self.update_power()
            self.update_health()
            self.output_data()

            time.sleep(constants.DELLIDRAC_SLEEP)


#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
