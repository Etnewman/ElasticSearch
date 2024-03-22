#!/etc/logstash/scripts/venv/bin/python3
# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This script dumps the contents of one ndjson file or campares
#          two ndjson files
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: compareNdjson.py
#
# Location: DevUtils (Not for operational use)
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Steve Truxal, 2023-03-16: Original Version
#
# Site/System: None
#
# Deficiency: N/A
#
# Use: Script used by Dev Team to prepare for deliveries
#
# Users: Not for use by users.
#
# DAC Setting: 755 root root
#
# Frequency: Used when needed
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
import re
import os
import sys, getopt


class ndJson:
    def __init__(self, file, printall):
        self.dashboards = {}
        self.indexPatterns = {}
        self.visuals = {}
        self.search = {}
        self.lens = {}
        self.configs = {}
        self.file = file

        self.num = 0
        self.dashboard_id_by_names = {}
        self.viz_id_by_names = {}
        self.ip_id_by_names = {}
        self.search_id_by_names = {}
        self.lens_id_by_names = {}

        self.parse(printall)

    #
    # Method: hasItem
    #    This is a generic method used to search for an item
    #    by id and name in the passed dictionaries
    #
    # Parameters:
    #   type - String describing type of item
    #   itemdict - dictionary of items indexed by item id
    #   namedict - dictionary of id's indexed by item name
    #   name - name of item to check for
    #   id - id of item to check for
    #
    # returns: None
    #
    def hasItem(self, type, itemdict, namedict, name, id):
        if not id in itemdict:
            if not name in namedict:
                print(type, "name:", name, "id:", id, "NOT FOUND")
            else:
                print(
                    type,
                    "ID not found but same name:",
                    name,
                    "has id:",
                    namedict[name],
                    "vs",
                    id,
                )

    #
    # Method: parse
    #    This method is used to read and parse an ndjson file.
    #    by id and name in the passed dictionaries
    #
    # Parameters:
    #   printall - Boolean; if true then print details about items
    #
    # returns: None
    #
    def parse(self, printall):
        f1 = open(self.file, "r")
        while True:
            fc = f1.readline()
            if not fc:
                break

            try:
                parsed = json.loads(fc)
            except:
                fc = fc.replace("\\", "")
                fc = re.sub('"{', "{", fc)
                fc = re.sub('}"', "}", fc)
                parsed = json.loads(fc)

            # print(json.dumps(parsed, indent=2))
            if "type" in parsed:

                if printall and parsed["type"] != "config":
                    print(
                        "Type:",
                        parsed["type"],
                        "id:",
                        parsed["id"],
                        parsed["attributes"]["title"],
                    )
                if parsed["type"] == "dashboard":
                    # print("Type:",parsed["type"],"id:",parsed["id"], parsed["attributes"]["title"], "updated_at:",parsed["updated_at"])
                    self.dashboards[parsed["id"]] = parsed
                    self.dashboard_id_by_names[parsed["attributes"]["title"]] = parsed[
                        "id"
                    ]
                elif parsed["type"] == "index-pattern":
                    self.indexPatterns[parsed["id"]] = parsed
                    self.ip_id_by_names[parsed["attributes"]["title"]] = parsed["id"]
                elif parsed["type"] == "visualization":
                    self.visuals[parsed["id"]] = parsed
                    self.viz_id_by_names[parsed["attributes"]["title"]] = parsed["id"]
                elif parsed["type"] == "lens":
                    self.lens[parsed["id"]] = parsed
                    self.lens_id_by_names[parsed["attributes"]["title"]] = parsed["id"]
                elif parsed["type"] == "search":
                    self.search[parsed["id"]] = parsed
                    self.search_id_by_names[parsed["attributes"]["title"]] = parsed[
                        "id"
                    ]
                elif parsed["type"] == "config":
                    self.configs[parsed["id"]] = parsed
                else:
                    print("unknown type", parsed["type"])
                    print("dumped:", json.dumps(parsed, indent=2))
            elif "missingReferences" in parsed:
                # print("found summary record", parsed)
                pass
            else:
                print("No type for object:", parsed)
            self.num = self.num + 1

        print("\nParsed:", self.file)
        print(
            "Summary:Dashboards=",
            len(self.dashboards),
            "Visuals=",
            len(self.visuals),
            "Lens=",
            len(self.lens),
            "index-patterns=",
            len(self.indexPatterns),
            "search=",
            len(self.search),
            "configs=",
            len(self.configs),
            "Total=",
            self.num,
        )

    #
    # Method: compare
    #    This method is used to compare two ndjson files. Currently
    #    the following types are compared:
    #        - Dashboards
    #        - Visualizations
    #        - Index Patterns
    #        - Lens Visuals
    #        - Searches
    #
    #   Note: The compare is only by id and name; a deep compare
    #         is not done.
    #
    # Parameters:
    #   compareNdJson - Instance of Ndjson class containing ndjson
    #                   information to compare.
    #
    # returns: None
    #
    def compare(self, compareNdjson):
        if isinstance(compareNdjson, ndJson):
            for key, value in compareNdjson.dashboards.items():
                self.hasItem(
                    "Dashboard",
                    self.dashboards,
                    self.dashboard_id_by_names,
                    value["attributes"]["title"],
                    key,
                )

            for key, value in compareNdjson.visuals.items():
                self.hasItem(
                    "Visualization",
                    self.visuals,
                    self.viz_id_by_names,
                    value["attributes"]["title"],
                    key,
                )

            for key, value in compareNdjson.indexPatterns.items():
                self.hasItem(
                    "Index Patterns",
                    self.indexPatterns,
                    self.ip_id_by_names,
                    value["attributes"]["title"],
                    key,
                )

            for key, value in compareNdjson.lens.items():
                self.hasItem(
                    "Lens",
                    self.lens,
                    self.lens_id_by_names,
                    value["attributes"]["title"],
                    key,
                )

            for key, value in compareNdjson.search.items():
                self.hasItem(
                    "Search",
                    self.search,
                    self.search_id_by_names,
                    value["attributes"]["title"],
                    key,
                )
        else:
            print("Incorrect object type passed to compare method")


#
# Method: deep_compare - (NOT CURRENTLY USED)
#    This function peforms a recursive compare on two objects
#
# Parameters:
#   obj1 - Object 1 for compare
#   obj2 - Object 2 for compare
#
# returns: None
#
def deep_compare(obj1, name, obj2, index):

    if isinstance(obj1, dict):
        for attribute, value in obj1.items():
            if name is None:
                deep_compare(value, attribute, obj2, 0)
            else:
                deep_compare(value, name + "." + attribute, obj2, 0)
    elif isinstance(obj1, list):
        listid = 0
        for item in obj1:
            deep_compare(item, name, obj2, listid)
            listid = listid + 1
    else:
        v = name.split(".")
        l = len(v)
        if l == 1:
            ob2val = obj2[v[0]]
        elif l == 2:
            hold = obj2[v[0]]
            if isinstance(hold, list):
                ob2val = obj2[v[0]][index][v[1]]
            else:
                ob2val = obj2[v[0]][v[1]]
        elif l == 3:
            ob2val = obj2[v[0]][v[1]][v[2]]

        if obj1 != ob2val:
            print(name, ":", obj1, " differs from", ob2val)


#
# Method: usage
#    This function prints usage information for the script
#
# Parameters: None
#
# returns: None
#
def usage():
    print(
        "\n\ncompareNdjson.py - Will parse and print information about one ndjson file"
    )
    print("                   or compare two ndjsonfiles. \n")
    print("                   The compare is done both ways")
    print("                   1st - see if all items in comparefile are in inputfile")
    print("                   2nd - see if all items in inputfile are in comparefile")
    print()
    print("  compareNdjson.py [-v] -i <inputfile> [-c <comparefile>]")
    print("    [-v] - optional for verbose output (print all object information)")
    print("    [-c <comparefile>] - optional parse and compare to 2nd ndjson file\n\n")


#
# Method: main
#    This function serves as the main entry for the script
#
# Parameters:
#     See usage function
#
# returns: None
#
def main():
    inputfile = None
    comparefile = None
    printall = False
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hi:c:v", ["ifile=", "cfile="])
    except getopt.GetoptError:
        usage()
        sys.exit(2)

    if len(sys.argv) < 2:
        usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt == "-h":
            usage()
            sys.exit(2)
        elif opt == "-v":
            printall = True
        elif opt in ("-i", "--ifile"):
            inputfile = arg
        elif opt in ("-c", "--cfile"):
            comparefile = arg

    if inputfile is None:
        usage()
        sys.exit(2)

    f1 = ndJson(inputfile, printall)

    if not comparefile is None:
        f2 = ndJson(comparefile, printall)

        print("\nComparing:", comparefile, "to", inputfile)
        f1.compare(f2)

        print("\nComparing:", inputfile, "to", comparefile)
        f2.compare(f1)


if __name__ == "__main__":
    main()
