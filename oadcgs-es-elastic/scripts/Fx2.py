# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class used to query data from FX2 blade servers.  It
#          derives from the Device class and runs in it's own thread to
#          query health and status information from the blade servers.
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: Fx2.py
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


class Fx2(Device):
    # All Fx2 Devices share the same output file so limit writing to one
    # Fx2 Object at a time using a mutex
    outfile_mutex = threading.Lock()

    #
    # Constructor
    #
    def __init__(self, devinfo):
        Device.__init__(self, devinfo.host, devinfo.devicetype, devinfo.hostname)
        self.setup_snmp(devinfo.user, devinfo.passwd, devinfo.privPass)

        self.ent_physical_desc = {}
        self.power_info = {}
        self.chassis_power_info = {}
        self.chassis_info = {}
        self.interfaces = {}
        self.health = self.DeviceDoc(DocType.HEALTH)
        self.health.set_health(Health.UNKNOWN)
        self.health.set_url("Not Defined")
        self.health.set_servicetag("Not Defined")
        self.temps = {}

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
        # 2.1.1 Defines system information (URL, Service Tag, etc)
        #
        health = self.get_pysnmpdata("DELL-RAC-MIB", "drsProductInfoGroup")
        # OID = 1.3.6.1.4.1.674.10892.2.1.1
        if self.__goodResult(health):
            for var in health.value:
                if var.tag == "drsProductURL":
                    urlval = var.val
                    self.health.set_url(urlval)

                if var.tag == "drsSystemServiceTag":
                    stval = var.val
                    self.health.set_servicetag(stval)

                self.health.set_value(var.tag, var.val)

        self.fqdn = self.health.get_value("systemFQDN")

        #
        # Get status for power, fan, blades
        # Remove Tempurature readings that are in another Document
        #
        health = self.get_pysnmpdata("DELL-RAC-MIB", "drsStatusNowGroup")
        # OID = 1.3.6.1.4.1.674.10892.2.3.1
        if self.__goodResult(health):
            for var in health.value:
                if not (
                    var.tag == "drsChassisFrontPanelAmbientTemperature"
                    or var.tag == "drsCMCAmbientTemperature"
                    or var.tag == "drsCMCProcessorTemperature"
                    or var.val == "N/A"
                    or var.val == "notApplicable"
                ):
                    if var.tag == "drsGlobalCurrStatus":
                        if var.val == "ok":
                            healthval = Health.OK
                        else:
                            healthval = Health.DEGRADED

                        self.health.set_health(healthval)

                    if var.val != "ok":
                        if var.tag == "drsIOMCurrStatus":
                            self.health.add_health_symptom(Symptom.DRSIOMCURRSTATUS)
                        elif var.tag == "drsKVMCurrStatus":
                            self.health.add_health_symptom(Symptom.DRSKVMCURRSTATUS)
                        elif var.tag == "drsRedCurrStatus":
                            self.health.add_health_symptom(Symptom.DRSREDCURRSTATUS)
                        elif var.tag == "drsPowerCurrStatus":
                            self.health.add_health_symptom(Symptom.DRSPOWERCURRSTATUS)
                        elif var.tag == "drsFanCurrStatus":
                            self.health.add_health_symptom(Symptom.DRSFANCURRSTATUS)
                        elif var.tag == "drsBladeCurrStatus":
                            self.health.add_health_symptom(Symptom.DRSBLADECURRSTATUS)
                        elif var.tag == "drsTempCurrStatus":
                            self.health.add_health_symptom(Symptom.DRSTEMPCURRSTATUS)
                        elif var.tag == "drsCMCCurrStatus":
                            self.health.add_health_symptom(Symptom.DRSCMCCURRSTATUS)

                self.health.set_value(var.tag, var.val)

            if len(self.health.get_health_symptoms()) == 0:
                self.health.add_health_symptom(Symptom.NONE)

    # Method: update_temps - retrieve and update temperature status
    #
    def update_temps(self):
        #
        # 2.3.1.10 Defines the front panel ambient temp
        temps = self.get_pysnmpdata(
            "DELL-RAC-MIB", "drsChassisFrontPanelAmbientTemperature"
        )
        # OID = 1.3.6.1.4.1.674.10892.2.3.1.10
        if self.__goodResult(temps):
            for var in temps.value:
                entry = self.DeviceDoc(DocType.TEMP)
                self.temps = entry
                self.temps.add_description("Front Panel TEMP Status")
                self.temps.set_value("time", time.time())
                self.temps.set_value(var.tag, var.val)

    #
    # Method: update_power - retrieve and update power supply information
    #
    def update_power(self):
        #
        # 2.4.2 Defines the overall power status
        power_info = self.get_pysnmpdata("DELL-RAC-MIB", "drsCMCPSUTable")
        # OID = 1.3.6.1.4.1.674.10892.2.4.2
        if self.__goodResult(power_info):
            for var in power_info.value:
                if not var.iid in self.power_info:
                    entry = self.DeviceDoc(DocType.POWER)
                    self.power_info[var.iid] = entry
                    entry.add_description("Overall Power Entry")
                else:
                    entry = self.power_info[var.iid]

                entry.set_value(var.tag, var.val)
                #
                #  To only add the query time once we check for a unique tag for each entry
                #
                if var.tag == "drsWattsResetTime":
                    entry.set_value("time", power_info.query_time)

    #
    # Method: chassis_power - retrieve and update chassis power supply information
    #
    def chassis_power(self):
        #
        # 2.4.1 Defines the overall chassis power status
        chassis_power_info = self.get_pysnmpdata("DELL-RAC-MIB", "drsCMCPowerTable")
        # OID = 1.3.6.1.4.1.674.10892.2.4.1
        if self.__goodResult(chassis_power_info):
            for var in chassis_power_info.value:
                if not var.iid in self.chassis_power_info:
                    entry = self.DeviceDoc(DocType.POWER)
                    self.chassis_power_info[var.iid] = entry
                    entry.add_description("Overall Power Entry")
                else:
                    entry = self.chassis_power_info[var.iid]

                entry.set_value(var.tag, var.val)
                #  To only add the query time once we check for a unique tag for each entry
                if var.tag == "drsWattsResetTime":
                    entry.set_value("time", chassis_power_info.query_time)

    #
    # Method: update_interfaces - retrieve and update interface information
    #
    def update_interfaces(self):
        #
        # 2.2.1 Defines interface data
        #
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
                elif var.tag == "ifType":
                    entry.add_description(var.val)

                # Uncomment for debugging
                # for key in self.interfaces:
                # print 'interface(', key, ')=', self.interfaces[key].print_all(), '\n'

    #
    # Method: chassis_info - retrieve fx2 chassis information
    #
    def update_chassis(self):
        #
        # 2.5.1.1 Defines the overall chassis status
        chassis_info = self.get_pysnmpdata("DELL-RAC-MIB", "drsCMCServerTableEntry")
        # OID = 1.3.6.1.4.1.674.10892.2.5.1.1
        if self.__goodResult(chassis_info):
            for var in chassis_info.value:
                if not var.iid in self.chassis_info:
                    entry = self.DeviceDoc(DocType.HARDWARE)
                    self.chassis_info[var.iid] = entry
                    entry.add_description("Overall Chassis Entry")
                else:
                    entry = self.chassis_info[var.iid]

                entry.set_value(var.tag, var.val)
                #
                #  To only add the query time once we check for a unique tag for each entry
                #
                if var.tag == "drsServerIndex":
                    entry.set_value("time", chassis_info.query_time)

            #
            # Remove entries that have N/A in them.  Need to work with copy
            # of dictionary to allow deleting items.
            #
            chassis_info_copy = copy.copy(self.chassis_info)
            for key in chassis_info_copy.keys():
                if (
                    "drsServerModel" in chassis_info_copy[key]
                    and chassis_info_copy[key].drsServerModel == "N/A"
                ):
                    del self.chassis_info[key]

            #
            # Uncomment to print results from removing N/A
            #
            # for key in self.chassis_info.keys():
            # 	print 'chassis(', key, ')=', self.chassis_info[key].toJSON(), '\n'

    #
    # Method: output_data - output current data to file
    #
    def output_data(self):
        Fx2.outfile_mutex.acquire()
        self.output(self.chassis_info)
        self.output(self.temps)
        self.output(self.power_info)
        self.output(self.chassis_power_info)
        self.output(self.health)
        self.output(self.interfaces)
        Fx2.outfile_mutex.release()

    #
    # Method: work - main work loop for thread
    #
    def work(self):

        while self.dowork:
            # Clear symptoms for next checkup
            self.health.clear_health_symptoms()

            self.update_chassis()
            self.update_temps()
            self.update_power()
            self.chassis_power()
            self.update_interfaces()
            self.update_health()
            self.output_data()

            # break # uncomment to run once through loop for testing
            time.sleep(constants.FX2_SLEEP)


#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
