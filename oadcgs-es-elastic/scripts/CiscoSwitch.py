# -*- coding: utf-8 -*-
#
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class used to query data from Cisco switches.  It
#          derives from the Device class and runs in its own thread to
#          query health and status information from Cisco Switches.
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
#            applicable Tracking, Author’s Name, date it was revised,
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
from Device import Device, DeviceType
from Document import DocType, Health, Symptom
import threading
import copy


class CiscoSwitch(Device):
    # All CiscoSwitch Devices share the same output file so limit writing to one
    # CiscoSwitch  Object at a time using a mutex
    outfile_mutex = threading.Lock()

    #
    # Constructor
    #
    def __init__(self, devinfo):
        Device.__init__(self, devinfo.host, devinfo.devicetype, devinfo.hostname)
        self.setup_snmp(devinfo.user, devinfo.passwd, devinfo.privPass)

        self.ent_physical_desc = {}
        self.fan_info = {}
        self.stats = self.DeviceDoc(DocType.STATS)
        self.power_info = {}
        self.sensor_info = {}
        self.interfaces = {}
        self.health = self.DeviceDoc(DocType.HEALTH)
        self.health.set_health(Health.UNKNOWN)
        self.health.set_url(devinfo.url)

    def __goodResult(self, result):
        retval = True
        if result.error != 0:
            self.health.add_health_symptom(Symptom.REQUEST_ERROR)
            retval = False

        return retval

    #
    # Method: update_health - Update overall health of device
    #
    # Note: This method should be called last to ensure all warning values can be set
    def update_health(self):
        self.health.set_health(Health.OK)

        if len(self.health.get_health_symptoms()) != 0:
            self.health.set_health(Health.DEGRADED)
        else:
            self.health.add_health_symptom(Symptom.NONE)

        self.health.set_value("time", time.time())
        self.health.add_description("Overall Health")

    #
    # Method: update_fans - retrieve and update fan status
    #
    def update_fans(self):
        # Query fan data
        # OID = 1.3.6.1.4.1.9.9.117.1.4.1.1.1
        fans = self.get_pysnmpdata(
            "CISCO-ENTITY-FRU-CONTROL-MIB", "cefcFanTrayOperStatus"
        )
        # Loop through returned values to correlate each index returned with the entity
        # physical description table to get the actual component the fan is on. A Document
        # is created for each fan and placed in the fan_info dictionary with the
        # entity physical description as the key.
        if self.__goodResult(fans):
            for var in fans.value:
                key = self.ent_physical_desc[int(var.iid)].val
                if not key in self.fan_info:
                    entry = self.DeviceDoc(DocType.FAN)
                    self.fan_info[key] = entry
                    entry.add_description(key)
                else:
                    entry = self.fan_info[key]

                entry.set_value(var.tag, var.val)
                entry.set_value("time", fans.query_time)

                if var.val != "up":
                    self.health.add_health_symptom(Symptom.FAN)

    #
    # Method: update_stats - retrieve and update cpu statistics
    #
    def update_stats(self):
        # Query cpu statistics
        # OID = 1.3.6.1.4.1.9.9.109.1.1.1.1
        cpu = self.get_pysnmpdata("CISCO-PROCESS-MIB", "cpmCPUTotalEntry")
        # Loop through returned values and add them to the stats dictionary. Also
        # add entity physical descption to cpu components returned
        if self.__goodResult(cpu):
            for var in cpu.value:
                self.stats.set_value(var.tag, var.val)

                if var.tag == "cpmCPUTotalPhysicalIndex":
                    if int(var.val) in self.ent_physical_desc.keys():
                        self.stats.add_description(
                            self.ent_physical_desc[int(var.val)].val
                        )

                # If 5 minute cpu average is greater than 80 set cpuWarning
                if var.tag == "cpmCPUTotal5minRev" and int(var.val) > 80:
                    self.health.add_health_symptom(Symptom.CPU)

            self.stats.set_value("time", cpu.query_time)

            totmem = int(self.stats.cpmCPUMemoryUsed) + int(self.stats.cpmCPUMemoryFree)
            usedpct = float(self.stats.cpmCPUMemoryUsed) / float(totmem)
            usedpct = round(usedpct, 4)
            self.stats.set_value("cpmCPUMemoryUsedPct", usedpct)
            if usedpct > 0.85:
                self.health.add_health_symptom(Symptom.MEMORY)

            self.stats.cpmCPUTotal1minRev = float(self.stats.cpmCPUTotal1minRev) / 100
            self.stats.cpmCPUTotal5minRev = float(self.stats.cpmCPUTotal5minRev) / 100
            self.stats.cpmCPUTotal5secRev = float(self.stats.cpmCPUTotal5secRev) / 100

    #
    # Method: update_power - retrieve and update power supply information
    #
    def update_power(self):
        # Query power supply data
        power = self.get_pysnmpdata(
            "CISCO-ENTITY-FRU-CONTROL-MIB", "cefcFRUPowerStatusEntry"
        )
        # OID = 1.3.6.1.4.1.9.9.117.1.1.2.1
        # Loop through returned values to correlate each index returned with the entity
        # physical description table to get the actual component the power supply is on.
        # Create a Document for each power supply and update with the retured information.
        if self.__goodResult(power):
            for var in power.value:
                key = self.ent_physical_desc[int(var.iid)].val
                if not key in self.power_info:
                    entry = self.DeviceDoc(DocType.POWER)
                    self.power_info[key] = entry
                    entry.add_description(key)
                else:
                    entry = self.power_info[key]

                entry.set_value(var.tag, var.val)
                #  To only add the query time once we check for a unique tag for each entry
                if var.tag == "cefcFRUPowerAdminStatus":
                    entry.set_value("time", power.query_time)

    def update_sensors(self):
        # Query power supply data
        sensor = self.get_pysnmpdata("CISCO-ENTITY-SENSOR-MIB", "entSensorValueEntry")
        # OID = 1.3.6.1.4.1.9.9.91.1.1.1.1
        # Loop through returned values to correlate each index returned with the entity
        # physical description table to get the actual component the sensor is on.
        # Create a Document for each sensor and update with the retured information.
        if self.__goodResult(sensor):
            self.sensor_info.clear()
            for var in sensor.value:
                key = self.ent_physical_desc[int(var.iid)].val
                if not key in self.sensor_info:
                    entry = self.DeviceDoc(DocType.TEMP)
                    self.sensor_info[key] = entry
                    entry.add_description(key)
                else:
                    entry = self.sensor_info[key]

                entry.set_value(var.tag, var.val)
                #  To only add the query time once we check for a unique tag for each entry
                if var.tag == "entSensorThresholdValue":
                    entry.set_value("time", sensor.query_time)

            HotSpot3k = float(0)
            tot7kCPUs = float(0)
            num7kCPUs = 0
            tot7kInlets = float(0)
            num7kInlets = 0
            inlet3k = float(0)
            inlet5k = float(0)
            num5kInlets = 0
            tot5kBigSurs = float(0)
            num5kBigSurs = 0

            # Now lets only hold the documents related to temperature (celsius) and only hold certian documments based on devicetype
            # Also check for overtemp conditions
            # On 5k switches we look at the "Fan-Side" sensor for inlet temps and the "Bigsur" sensor for cpu temps
            # On 7k switches we look at the "Inlet" and "CPU" sensors as they are named accordingly
            # On Catalyst switches we look at the "Inlet" sensor for inlet temps and the "HotSpot" sensor for cpu temps
            # On all switches minor and major temperature violations are flagged
            try:
                sensor_info_copy = copy.copy(self.sensor_info)
                for key in sensor_info_copy.keys():
                    if (
                        sensor_info_copy[key].entSensorType != "celsius"
                        or sensor_info_copy[key].entSensorValueTimeStamp == "0"
                        or sensor_info_copy[key].entSensorValue == "0"
                    ):
                        del self.sensor_info[key]
                    elif self.devicetype == DeviceType.NEXUS5K:
                        if "Fan-Side" in sensor_info_copy[key].metadata["Desc"]:
                            inlet5k = float(sensor_info_copy[key].entSensorValue)
                            num5kInlets = num5kInlets + 1
                        elif "Bigsur" in sensor_info_copy[key].metadata["Desc"]:
                            tot5kBigSurs = tot5kBigSurs + float(
                                sensor_info_copy[key].entSensorValue
                            )
                            num5kBigSurs = num5kBigSurs + 1
                    elif self.devicetype == DeviceType.NEXUS7K:
                        if "CPU" in sensor_info_copy[key].metadata["Desc"]:
                            tot7kCPUs = tot7kCPUs + float(
                                sensor_info_copy[key].entSensorValue
                            )
                            num7kCPUs = num7kCPUs + 1
                        elif "Inlet" in sensor_info_copy[key].metadata["Desc"]:
                            tot7kInlets = tot7kInlets + float(
                                sensor_info_copy[key].entSensorValue
                            )
                            num7kInlets = num7kInlets + 1
                    elif self.devicetype == DeviceType.CATALYST:
                        if sensor_info_copy[key].entSensorMeasuredEntity == "0":
                            del self.sensor_info[key]
                        else:
                            if "Inlet" in sensor_info_copy[key].metadata["Desc"]:
                                inlet3k = float(sensor_info_copy[key].entSensorValue)
                                self.health.set_temp("inlet", inlet3k)
                                if (
                                    inlet3k > constants.CISCOSWITCH_INLETMAJOR_3KTEMP
                                ):  #  Catalyst temp over 56.0
                                    self.health.add_health_symptom(
                                        Symptom.INLET_MAJOR_TEMP
                                    )
                                elif (
                                    inlet3k > constants.CISCOSWITCH_INLETMINOR_3KTEMP
                                ):  #  Catalyst temp over 46.0
                                    self.health.add_health_symptom(
                                        Symptom.INLET_MINOR_TEMP
                                    )
                            elif "HotSpot" in sensor_info_copy[key].metadata["Desc"]:
                                HotSpot3k = float(sensor_info_copy[key].entSensorValue)
                                self.health.set_temp("cpu", HotSpot3k)
                                if (
                                    HotSpot3k > constants.CISCOSWITCH_CPUMAJOR_3KTEMP
                                ):  #  Catalyst temp over 125.0
                                    self.health.add_health_symptom(
                                        Symptom.CPU_MAJOR_TEMP
                                    )
                                elif (
                                    HotSpot3k > constants.CISCOSWITCH_CPUMINOR_3KTEMP
                                ):  #  Catalyst temp over 105.0
                                    self.health.add_health_symptom(
                                        Symptom.CPU_MINOR_TEMP
                                    )

                if self.devicetype == DeviceType.NEXUS7K:
                    if num7kCPUs > 0:
                        avg7kCPU = tot7kCPUs / num7kCPUs
                        self.health.set_temp("cpu", avg7kCPU)
                        if (
                            avg7kCPU > constants.CISCOSWITCH_CPUMAJOR_7KTEMP
                        ):  # 7k temp over 85.0
                            self.health.add_health_symptom(Symptom.CPU_MAJOR_TEMP)
                        elif (
                            avg7kCPU > constants.CISCOSWITCH_CPUMINOR_7KTEMP
                        ):  # 7k temp over 75.0
                            self.health.add_health_symptom(Symptom.CPU_MINOR_TEMP)

                    if num7kInlets > 0:
                        avg7kInlets = tot7kInlets / num7kInlets
                        self.health.set_temp("inlet", avg7kInlets)
                        if (
                            avg7kInlets > constants.CISCOSWITCH_INLETMAJOR_7KTEMP
                        ):  # Avg 7k temp over 60.0
                            self.health.add_health_symptom(Symptom.INLET_MAJOR_TEMP)
                        elif (
                            avg7kInlets > constants.CISCOSWITCH_INLETMINOR_7KTEMP
                        ):  # Avg 7k temp over 42.0
                            self.health.add_health_symptom(Symptom.INLET_MINOR_TEMP)

                elif self.devicetype == DeviceType.NEXUS5K:
                    if num5kInlets > 0:
                        self.health.set_temp("inlet", inlet5k)
                        if (
                            inlet5k > constants.CISCOSWITCH_INLETMAJOR_5KTEMP
                        ):  # 5k temp over 110.0
                            self.health.add_health_symptom(Symptom.INLET_MAJOR_TEMP)
                        elif (
                            inlet5k > constants.CISCOSWITCH_INLETMINOR_5KTEMP
                        ):  # 5k temp over 100.0
                            self.health.add_health_symptom(Symptom.INLET_MINOR_TEMP)

                    if num5kBigSurs > 0:
                        avg5kBigSurs = tot5kBigSurs / num5kBigSurs
                        self.health.set_temp("cpu", avg5kBigSurs)
                        if (
                            avg5kBigSurs > constants.CISCOSWITCH_CPUMAJOR_5KTEMP
                        ):  # 5k temp over 125.0
                            self.health.add_health_symptom(Symptom.CPU_MAJOR_TEMP)
                        elif (
                            avg5kBigSurs > constants.CISCOSWITCH_CPUMINOR_5KTEMP
                        ):  # 5k temp over 110.0
                            self.health.add_health_symptom(Symptom.CPU_MINOR_TEMP)

            except Exception as e:
                print("Unable to evaluate temperature sensors for : ", self.hostname)
                print("Exception:", str(e))

            # Uncomment for debugging
            # for key in self.sensor_info:
            #    print('sensor_info(', key, ')=', self.sensor_info[key].toJSON())

    def update_interfaces(self):
        timedelta = {}
        #
        # To get all data for interfaces we need to walk 2 OIDs.  The 32 bit Iftable ad the 64 bit ifXtable
        #
        # We will walk the ifXtable first to get needed values
        # Query ifXEntry interface data (64 Bit)
        intfc = self.get_pysnmpdata("IF-MIB", "ifXEntry")
        # OID = 1.3.6.1.2.1.31.1.1.1

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
                # Note that this code does not execute on the 1st query
                # Let calculate interface utilization using this queries values
                # against last queries values
                if var.tag == "ifHCInOctets":
                    currVal = entry.get_value(var.tag)
                    if (
                        currVal != "Attribute does not exist"
                        and entry.get_value("ifType") != "propVirtual"
                    ):
                        speed = int(entry.get_value("ifHighSpeed")) * 1000000
                        if speed != 0:
                            diff = int(var.val) - int(currVal)

                            utilization = (diff * 8) / (timedelta[var.iid] * speed)
                            utilization = round(utilization, 4)

                            entry.set_value("inputUtilization", utilization)
                            entry.set_value("inputTimeDelta", timedelta[var.iid])

                            if (
                                entry.isUplink == "true"
                                and utilization > constants.CISCOSWITCH_UTILIZATION
                            ):
                                self.health.add_health_symptom(
                                    Symptom.INPUT_UTILIZATION
                                )
                                entry.set_value("inputUtilizationWarning", "true")
                            else:
                                entry.set_value("inputUtilizationWarning", "false")

                elif var.tag == "ifHCOutOctets":
                    currVal = entry.get_value(var.tag)
                    if (
                        currVal != "Attribute does not exist"
                        and entry.get_value("ifType") != "propVirtual"
                    ):
                        speed = int(entry.get_value("ifHighSpeed")) * 1000000
                        if speed != 0:
                            diff = int(var.val) - int(currVal)

                            utilization = (diff * 8) / (timedelta[var.iid] * speed)
                            utilization = round(utilization, 4)

                            entry.set_value("outputUtilization", utilization)
                            entry.set_value("outputTimeDelta", timedelta[var.iid])

                            if entry.isUplink == "true" and utilization > 0.95:
                                self.health.add_health_symptom(
                                    Symptom.OUTPUT_UTILIZATION
                                )
                                entry.set_value("outputUtilizationWarning", "true")
                            else:
                                entry.set_value("outputUtilizationWarning", "false")

                # Set the new value in the document
                entry.set_value(var.tag, var.val)
                if var.tag == "ifName":
                    entry.set_value("time", intfc.query_time)
                    entry.add_description(var.val)
                elif var.tag == "ifAlias":
                    if "uplink" in var.val.lower():
                        entry.set_value("isUplink", "true")
                    else:
                        entry.set_value("isUplink", "false")
        #
        # Now walk the iftable
        # Query IfEntry interface data (32 Bit)
        intfc = self.get_pysnmpdata("IF-MIB", "ifEntry")
        # OID = 1.3.6.1.2.1.2.2.1

        if self.__goodResult(intfc):
            # Loop through returned values and create a Document for each interface returned.
            for var in intfc.value:
                if var.iid in self.interfaces:
                    entry = self.interfaces[var.iid]
                else:
                    print("ifEntry Interface not found in ifXEntry table")
                    continue

                if (
                    var.tag == "ifType"
                    or var.tag == "ifMtu"
                    or var.tag == "ifAdminStatus"
                    or var.tag == "ifOperStatus"
                    or var.tag == "ifPhysAddress"
                    or var.tag == "ifDescr"
                ):
                    entry.set_value(var.tag, var.val)

                # Check port status on uplink ports to ensure if they are administratively up then they are also operational
                if var.tag == "ifOperStatus" and entry.isUplink == "true":
                    # Get adminStats value and make sure its valid
                    adminStatus = entry.get_value("ifAdminStatus")
                    if adminStatus != "Attribute does not exist":
                        if adminStatus == "up" and var.val != "up":
                            self.health.add_health_symptom(Symptom.OPSTATE)

    #
    # Method: output_data - output current data to file
    #
    def output_data(self):
        CiscoSwitch.outfile_mutex.acquire()
        self.output(self.sensor_info)
        self.output(self.interfaces)
        self.output(self.fan_info)
        self.output(self.stats)
        self.output(self.power_info)
        self.output(self.health)
        CiscoSwitch.outfile_mutex.release()

    #
    # Method: work - main work loop for thread
    #
    def work(self):
        # First get entity List to build entity dictionary
        # Do not continue until entity list retrieved sucessfully
        haveEntityVals = False
        while not haveEntityVals:
            entity = self.get_pysnmpdata("ENTITY-MIB", "entPhysicalDescr")
            # OID = 1.3.6.1.2.1.47.1.1.1.1.2
            if self.__goodResult(entity):
                for var in entity.value:
                    self.ent_physical_desc[int(var.iid)] = var
                haveEntityVals = True
            else:
                print(
                    "Warning: Unable to retrieve Entity values for:",
                    self.hostname,
                    "will try again in",
                    constants.CISCOSWITCH_SLEEP,
                    "seconds.",
                )
                time.sleep(constants.CISCOSWITCH_SLEEP)

        while self.dowork:
            # for i in range(0,2):
            # Clear symptoms for next checkup
            self.health.clear_health_symptoms()

            self.update_stats()
            self.update_sensors()
            self.update_interfaces()
            self.update_fans()
            self.update_power()
            self.update_health()

            self.output_data()
            # break # uncomment to run once through loop for testing
            time.sleep(constants.CISCOSWITCH_SLEEP)


#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
