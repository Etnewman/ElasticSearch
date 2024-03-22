# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This file contains the Document Class used for the creation of documents in
#          Elasticsearch.
#          The following classes are also present in this file:
# 			 DocType - Values are used to specify document type
# 			 Meta - Used to create nested metadata fields
# 			 Host - Used to create nested host fields
#            License - Used to device status of Licenses
#            Health - Used to define health of a device
#            Symptom - Used to list symptoms of health problems
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: Document.py
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
# Frequency: Document objects are continuously created by this application
#
# Information Security Authorization
# ACC/A26 IA Approval: year-mm-dd, Name, ACC ISSE
#
# Lead System Engineering Authorization
# AF-DCGS LSE Approval: year-mm-dd, Name, AF-DCGS/AO
#
###########################################################################
#
import json


class License:
    OK = "OK"
    EXPIRED = "Expired"
    EXPIRING = "Expiring"
    INVALID = "Invalid"
    UNKNOWN = "Unknown"


class Health:
    OK = "OK"
    DEGRADED = "Degraded"
    DOWN = "Down"
    UNKNOWN = "Unknown"
    STALE = "Stale"


class Symptom:
    OUTPUT_UTILIZATION = "OutputUtilization"
    INPUT_UTILIZATION = "InputUtilization"
    CPU = "CpuUtilization"
    OPSTATE = "UplinkOperationalStatus"
    MEMORY = "MemoryUtilization"
    CPU_MAJOR_TEMP = "CPU Major OverTemp"
    CPU_MINOR_TEMP = "CPU Minor OverTemp"
    INLET_MAJOR_TEMP = "Inlet Major OverTemp"
    INLET_MINOR_TEMP = "Inlet Minor OverTemp"
    TEMP = "OverTemperature"
    FAN = "FanDegraded"
    NONE = "None"
    NONE_AUDIT = "none"
    REQUEST_ERROR = "ErrorRequestingData"
    GLOBALSYSTEMSTATUS = "globalSystemStatus"
    GLOBALSTORAGESTATUS = "globalStorageStatus"
    SYSTEMLCDSTATUS = "systemLCDStatus"
    SYSTEMPOWERSTATE = "systemPowerState"
    SYSTEMPOWERUPTIME = "systemPowerUpTime"
    DRSBLADECURRSTATUS = "drsBladeCurrStatus"
    DRSCMCCURRSTATUS = "drsCMCCurrStatus"
    DRSFANCURRSTATUS = "drsFanCurrStatus"
    DRSIOMCURRSTATUS = "drsIOMCurrStatus"
    DRSKVMCURRSTATUS = "drsKVMCurrStatus"
    DRSREDCURRSTATUS = "drsRedCurrStatus"
    DRSPOWERCURRSTATUS = "drsPowerCurrStatus"
    DRSTEMPCURRSTATUS = "drsTempCurrStatus"
    NO_AUDITS = "No_Audits"
    CONNECTION_ERROR = "ConnectionError"
    EMPTY_RESPONSE = "EmptyResponse"
    NOT_RUNNING = "NotRunning"
    RESTARTING = "ThreadRestarting"


# Used like constants when specifying docType for the Document class
# Note: Any new document types should be added here
class DocType:
    HEALTH = "health"
    FAN = "fan"
    TEMP = "temp"
    POWER = "power"
    SHARE = "share"
    EXPORT = "export"
    CPUSTATS = "cpustats"
    INTERFACE = "interface"
    CAPACITY = "capacity"
    DISK = "disk"
    LICENSE = "license"
    STATUS = "status"
    STATS = "stats"
    HARDWARE = "hardware"
    PARTITION = "partition"
    MEMORY = "memory"
    NODE = "node"
    EVENT = "event"


class DocSubtype:
    HOST = "host"
    DEVICE = "device"
    APP = "app-overall"
    GROUP = "group"
    VSPHERE = "vsphere"
    DATA_COLLECTOR = "datacollector"


# Class: Document - The document class is used to create documents that will
#                   be ingested into Elasticsearch
class Document:
    def __init__(self, docType, docSubtype, deviceType=None, name=None):
        self.metadata = {"DocType": docType}
        if docSubtype is not None:
            self.metadata["DocSubtype"] = docSubtype
            if docSubtype == DocSubtype.APP:
                self.app = {}
                self.app["Name"] = name
            elif docSubtype == DocSubtype.GROUP:
                self.group = {}
                self.group["Name"] = name
            else:
                self.host = {}
                if name is not None:
                    self.host["name"] = name.split(".")[0]

        if deviceType is not None:
            self.host["type"] = deviceType
            self.host["hostname"] = name.split(".")[0]

    # The following methods are overrides of built in methods
    def __setitem__(self, name, value):
        return setattr(self, name, value)

    def __getitem__(self, name):
        return getattr(self, name)

    def __contains__(self, name):
        return hasattr(self, name)

    def listAttr(self):
        for item in self.__dict__:
            print("Attrib:", item)

    def loadjson(self, j):
        self.__dict__ = json.loads(j)
        if "name" in self.host.keys():
            self.host["name"] = self.host["name"].split(".")[0]
        # vals = json.loads(j)
        # for val in vals:
        #   self.set_value(val, vals[val])
        #   print("Val=", val, "-", type(val))
        # for item in self.host:
        #     print("Host item:", item, "-", self.host[item])
        # print("MYSELF=",self.toJSON())

    # Method: set_value - method used to add/set attributes
    # Parameters:
    #    tag - attribute to add/set
    #    value - value of attribute
    def set_value(self, tag, value):
        self[tag] = value

    # Method: get_value - method used retreive attribute value
    # Parameters:
    #    tag - attribute to add/set
    # Returns:
    #   - Value of Attribute
    #   - error message if attribute does not exist
    def get_value(self, tag):
        if hasattr(self, tag):
            return self[tag]
        else:
            return "Attribute does not exist"

    # Method: print_json - Used to print object attributes
    def print_json(self):
        print(self.toJSON())

    # Method: add_desciption - method used to add/set a metadata
    #         description to the Document
    # Parameters:
    #    desc - Description to add
    def add_description(self, desc):
        self.metadata["Desc"] = desc

    def set_url(self, url):
        self.host["Url"] = url

    def set_servicetag(self, servicetag):
        self.host["ServiceTag"] = servicetag

    def set_license(self, license_val):
        self.host["License"] = license_val

    def add_subtype(self, subtype):
        self.metadata["DocSubtype"] = subtype

    def set_temp(self, name, temp):
        if not self.__contains__("Temp"):
            self.Temp = {}

        self.Temp[name] = temp

    # Method: set_health - method used to set a Health
    #         field in the host nested field
    # Parameters:
    #    health - health value
    def set_health(self, health):
        if self.metadata["DocSubtype"] == DocSubtype.APP:
            self.app["Health"] = health
        elif self.metadata["DocSubtype"] == DocSubtype.GROUP:
            self.group["Health"] = health
        else:
            self.host["Health"] = health

    def get_health(self):
        retval = Health.UNKNOWN
        if self.metadata["DocSubtype"] == DocSubtype.APP:
            if "Health" not in self.app.keys():
                self.app["Health"] = Health.UNKNOWN
            retval = self.app["Health"]
        elif self.metadata["DocSubtype"] == DocSubtype.GROUP:
            if "Health" not in self.group.keys():
                self.group["Health"] = Health.UNKNOWN
            retval = self.group["Health"]
        else:
            if "Health" not in self.host.keys():
                self.host["Health"] = Health.UNKNOWN
            retval = self.host["Health"]

        return retval

    def get_hostname(self):
        return self.host["name"]

    # Method: set_health_symptoms - method used to set a Health
    #         Symptom
    # Parameters:
    #    symptoms - List of Symptoms
    def set_health_symptoms(self, symptoms):
        if self.metadata["DocSubtype"] == DocSubtype.APP:
            self.app["HealthSymptoms"] = symptoms
        elif self.metadata["DocSubtype"] == DocSubtype.GROUP:
            self.group["HealthSymptoms"] = symptoms
        else:
            self.host["HealthSymptoms"] = symptoms

    def add_health_symptom(self, symptom):
        if self.metadata["DocSubtype"] == DocSubtype.APP:
            if "HealthSymptoms" not in self.app.keys():
                self.app["HealthSymptoms"] = list()
            if symptom not in self.app["HealthSymptoms"]:
                self.app["HealthSymptoms"].append(symptom)
        elif self.metadata["DocSubtype"] == DocSubtype.GROUP:
            if "HealthSymptoms" not in self.group.keys():
                self.group["HealthSymptoms"] = list()
            if symptom not in self.group["HealthSymptoms"]:
                self.group["HealthSymptoms"].append(symptom)
        else:
            if "HealthSymptoms" not in self.host.keys():
                self.host["HealthSymptoms"] = list()
            if symptom not in self.host["HealthSymptoms"]:
                self.host["HealthSymptoms"].append(symptom)

    def get_health_symptoms(self):
        retval = list()
        if self.metadata["DocSubtype"] == DocSubtype.APP:
            if "HealthSymptoms" in self.app.keys():
                retval = self.app["HealthSymptoms"]
        elif self.metadata["DocSubtype"] == DocSubtype.GROUP:
            if "HealthSymptoms" in self.group.keys():
                retval = self.group["HealthSymptoms"]
        else:
            if "HealthSymptoms" in self.host.keys():
                retval = self.host["HealthSymptoms"]

        return retval

    def clear_health_symptoms(self):
        if self.metadata["DocSubtype"] == DocSubtype.APP:
            if "HealthSymptoms" in self.app.keys():
                del self.app["HealthSymptoms"][:]
        elif self.metadata["DocSubtype"] == DocSubtype.GROUP:
            if "HealthSymptoms" in self.group.keys():
                del self.group["HealthSymptoms"][:]
        else:
            if "HealthSymptoms" in self.host.keys():
                del self.host["HealthSymptoms"][:]

    def has_symptom(self, symptom):
        retval = False
        if self.metadata["DocSubtype"] == DocSubtype.APP:
            if "HealthSymptoms" in self.app.keys():
                if symptom in self.app["HealthSymptoms"]:
                    retval = True
        elif self.metadata["DocSubtype"] == DocSubtype.GROUP:
            if "HealthSymptoms" in self.group.keys():
                if symptom in self.group["HealthSymptoms"]:
                    retval = True
        else:
            if "HealthSymptoms" in self.host.keys():
                if symptom in self.host["HealthSymptoms"]:
                    retval = True

        return retval

    def add_app_hosts(self, hosts):
        self.app["requiredHosts"] = hosts

    @staticmethod
    def json_default(val):
        if isinstance(val, bytes):
            return val.decode("UTF-8")
        else:
            return val.__dict__

    # Method: toJSON - method used to output attributes in json
    def toJSON(self):
        retval = "None"
        try:
            retval = json.dumps(self, default=Document.json_default)
        except Exception as e:
            print("Issue on json dumps for val:", vars(self))
            print(str(e))
        return retval


#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
