# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class used to query data from Data Domain storage devices.
#          It derives from the Device class and runs in it's own thread to
#          query health and status information from Data Domain devices.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: DataDomain.py
#
# Location: /etc/logstash/scripts
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Corey Maher, 2021-01-27: Original Version
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
from Device import DeviceType
from DeviceInfo import DeviceInfo, SNMPDeviceInfo
import inspect
import threading


class DataDomain(Device):
    # All DataDomain Devices share the same output file so limit writing to one
    # DataDomain Object at a time using a mutex
    outfile_mutex = threading.Lock()

    #
    # Constructor
    #
    def __init__(self, devinfo):
        Device.__init__(self, devinfo.host, devinfo.devicetype, devinfo.hostname)
        self.setup_snmp(devinfo.user, devinfo.passwd, devinfo.privPass, devinfo.timeout)

        self.ent_physical_desc = {}
        self.stats = self.DeviceDoc(DocType.STATS)
        self.license_info = {}
        self.filesystem_used = {}
        self.sensor_info = {}
        self.disk_info = {}
        self.filesystem_info = {}
        self.health = self.DeviceDoc(DocType.HEALTH)
        self.health.set_health(Health.UNKNOWN)
        self.health.set_url(devinfo.url)
        self.health_symptoms = list()

    def __goodResult(self, result):
        retval = True
        if result.error != 0:
            self.health.add_health_symptom(Symptom.REQUEST_ERROR)
            self.health.set_health(Health.UNKNOWN)
            print("DataDomain - Request Error:", result.errorStr)
            print("Caller is", inspect.stack()[1][3])
            retval = False

        return retval

    #
    # Method: update_health - Update overall health of device
    #
    # Note: This method should be called last to ensure all warning values can be set
    def update_health(self):
        health = self.get_pysnmpdata("DATA-DOMAIN-MIB", "systemProperties")
        # OID = 1.3.6.1.4.1.19746.1.13.1
        self.health.set_value("time", health.query_time)
        if self.__goodResult(health):
            for var in health.value:
                # print  "ID=", var.iid, '-- tag:',var.tag, var.iid, "=", var.val, '(',var.type,')' "index=", var.iid
                self.health.set_value(var.tag, var.val)

            self.health.add_description("Overall Health")
            self.health.systemCurrentTime = self.health.systemCurrentTime.rstrip()

            # Turn availability values into floats
            try:
                self.health.systemAvailability = (
                    float(self.health.systemAvailability) / 100
                )
                self.health.systemAvailabilityExcCtrlDowntime = (
                    float(self.health.systemAvailabilityExcCtrlDowntime) / 100
                )
                self.health.systemFsAvailability = (
                    float(self.health.systemFsAvailability) / 100
                )
                self.health.systemFsAvailabilityExcCtrlDowntime = (
                    float(self.health.systemFsAvailabilityExcCtrlDowntime) / 100
                )
            except:
                print("unable to access health field in Data Domain Class")

            if (
                self.health.systemAvailabilityExcCtrlDowntime
                < constants.DATADOMAIN_DOWNTIME
                or self.health.systemFsAvailabilityExcCtrlDowntime
                < constants.DATADOMAIN_DOWNTIME
            ):
                self.health.set_health(Health.DEGRADED)
            else:
                self.health.set_health(Health.OK)

            # print "Health=", self.health.toJSON()

    def update_disk_util(self):
        # Query disk data
        disk = self.get_pysnmpdata("DATA-DOMAIN-MIB", "diskStorage")
        # OID = 1.3.6.1.4.1.19746.1.6
        # Loop through returned values to correlate each index returned with the entity
        # physical description table to get the actual component the fan is on. A Document
        # is created for each fan and placed in the fan_info dictionary with the
        # entity physical description as the key.
        if self.__goodResult(disk):
            for var in disk.value:
                key = var.iid
                if not key in self.disk_info:
                    entry = self.DeviceDoc(DocType.DISK)
                    self.disk_info[key] = entry
                    entry.add_description("Disk Information")
                else:
                    entry = self.disk_info[key]

                entry.set_value(var.tag, var.val)

                # Only set the time once for each item in dictionary
                if var.tag == "diskSerialNumber":
                    entry.set_value("time", disk.query_time)

                # Uncomment for debugging
                # print "Index=", var.iid, "Val:",var.val, '-- tag:',var.tag, var.iid, "=", var.val, '(',var.type,')'

            # Uncomment for debugging
            # for key in self.disk_info:
            # 	print 'disk_info(', key, ')=', self.disk_info[key].toJSON()

    def update_filesystem_used(self):
        # Query file system data
        filesystems = self.get_pysnmpdata("DATA-DOMAIN-MIB", "fileSystemSpace")
        # OID = 1.3.6.1.4.1.19746.1.3.2
        # Loop through returned values to correlate each index returned with the entity
        # physical description table to get the actual component the fan is on. A Document
        # is created for each fan and placed in the fan_info dictionary with the
        # entity physical description as the key.
        if self.__goodResult(filesystems):
            for var in filesystems.value:
                key = var.iid
                if not key in self.filesystem_info:
                    entry = self.DeviceDoc(DocType.CAPACITY)
                    self.filesystem_info[key] = entry
                    entry.add_description("Filesystem Capacity Information")
                else:
                    entry = self.filesystem_info[key]

                entry.set_value(var.tag, var.val)

                # Only set the time once for each item in dictionary
                if var.tag == "fileSystemResourceName":
                    entry.set_value("time", filesystems.query_time)

                # Uncomment for debugging
                # print  self.filesystem_resource_name[int(var.iid)].val, '-- tag:',var.tag, var.iid, "=", var.val, '(',var.type,')' "index=", var.iid

            # Uncomment for debugging
            # for key in self.filesystem_info:
            # 	print 'filesystem_info(', key, ')=', self.filesystem_info[key].toJSON()

    def update_sensors(self):
        # Query power supply data
        sensors = self.get_pysnmpdata("DATA-DOMAIN-MIB", "temperatures")
        # OID = 1.3.6.1.4.1.19746.1.1.2
        # Loop through returned values to correlate each index returned with the entity
        # physical description table to get the actual component the sensor is on.
        # Create a Document for each sensor and update with the retured information.
        if self.__goodResult(sensors):
            for var in sensors.value:
                key = var.iid
                if not key in self.sensor_info:
                    entry = self.DeviceDoc(DocType.TEMP)
                    self.sensor_info[key] = entry
                    entry.add_description("Temperature Information")
                else:
                    entry = self.sensor_info[key]

                entry.set_value(var.tag, var.val)

                # Only set the time once for each item in dictionary
                if var.tag == "tempSensorCurrentValue":
                    entry.set_value("time", sensors.query_time)

            # Uncomment for debugging
            # for key in self.sensor_info:
            # 	print 'sensor_info(', key, ')=', self.sensor_info[key].toJSON()

    #
    # Method: output_data - output current data to file
    #
    def output_data(self):
        DataDomain.outfile_mutex.acquire()
        self.output(self.disk_info)
        self.output(self.filesystem_info)
        self.output(self.sensor_info)
        self.output(self.health)
        DataDomain.outfile_mutex.release()

    #
    # Method: work - main work loop for thread
    #
    def work(self):
        while self.dowork:
            # Clear symptoms for next checkup
            self.health.clear_health_symptoms()

            self.update_sensors()
            self.update_filesystem_used()
            self.update_disk_util()
            self.update_health()

            self.output_data()

            time.sleep(constants.DATADOMAIN_SLEEP)


def main():

    print("starting datadomain...")
    datadomain = SNMPDeviceInfo()
    datadomain.setup(
        "10.1.60.43",
        DeviceType.DATADOMAIN,
        "Monitoring",
        "41@wC$rOrsbcRuE",
        "41@wC$rOrsbcRuE",
        "ech-datadomain",
        "https://10.1.60.43",
        1500000,
    )

    # Monitor all threads from main and if any exit unexpectedly log error
    dd = DataDomain(datadomain)
    dd.start()
    dd.join()
    print("Finished")


if __name__ == "__main__":
    main()
#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
