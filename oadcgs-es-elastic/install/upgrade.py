# -*- coding: utf-8 -*-
# 			               Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: python script used to upgrade an Elastic node, called by
#          upgrade_node.sh
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: upgrade.py
#
# Location: "install" directory of elastic repo on repo server
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, date it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Steve Truxal, 2021-03-22: Original Version
#
# Site/System: Repo Server (ro01)
#
# Deficiency: N/A
#
# Use: This script is used by the Elastic Installer
#
# Users: Elastic Installer sudoed to root user
#
# DAC Setting: 755 apache apache
# Required SELinux Security Context : httpd_sys_content_t
#
# Frequency: During Elastic Upgrade process
#
# Information Security Authorization
# ACC/A26 IA Approval: year-mm-dd, Name, ACC ISSE
#
# Lead System Engineering Authorization
# AF-DCGS LSE Approval: year-mm-dd, Name, AF-DCGS/AO
#
###########################################################################
#
import os, socket, getpass, time, sys
import requests
from requests import Request, Session
import urllib3
import getopt
import pwd

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


class DeviceData:
    def __init__(self):
        self.query_time = 0
        self.error = 0
        self.errorStr = ""
        self.value = 0


class Upgrade:
    def __init__(self, user, passwd, force):
        if user is None:
            self.rest_user = os.getlogin()
        else:
            self.rest_user = user

        self.rest_passwd = passwd
        self.host = socket.gethostname()
        self.rest_port = 9200
        self.rest_session = 0
        self.headers = {"Content-Type": "application/json"}
        self.force = force

    def _restSession(self):
        # print "User:", self.rest_user, " Password: ", self.rest_passwd
        self.rest_session = requests.Session()
        self.rest_session.auth = (self.rest_user, self.rest_passwd)
        self.rest_session.verify = False

    # Method: get_restdata - Used to get data from device
    # Parameters:
    #    oid - Object Identifier for SNMP walk on device
    # Returns:
    #   - result of rest request
    #   - query_time - Time of query (Right after)
    def get_restdata(self, url):
        retval = DeviceData()

        if self.rest_session == 0:
            self._restSession()

        requrl = "https://" + self.host + ":" + str(self.rest_port) + "/" + url
        # print (requrl)
        try:
            r = self.rest_session.get(requrl, timeout=10)
            retval.query_time = time.time()
            retval.value = r.json()
            if r.status_code == 200:
                retval.error = 0
            else:
                retval.error = -1
        except:
            retval.error = -1

        return retval

    def put_restdata(self, url, reqdata):
        retval = DeviceData()

        if self.rest_session == 0:
            self._restSession()

        requrl = "https://" + self.host + ":" + str(self.rest_port) + "/" + url
        try:
            r = self.rest_session.put(
                requrl, headers=self.headers, data=reqdata, timeout=10
            )
            retval.query_time = time.time()
            retval.value = r.json()
            if r.status_code == 200:
                retval.error = 0
            else:
                retval.error = -1
        except:
            retval.error = -1

        return retval

    def post_restdata(self, url):
        retval = DeviceData()

        if self.rest_session == 0:
            self._restSession()

        requrl = "https://" + self.host + ":" + str(self.rest_port) + "/" + url

        try:
            r = self.rest_session.post(requrl, timeout=60)
            retval.query_time = time.time()
            retval.value = r.json()
            if r.status_code == 200:
                retval.error = 0
            else:
                retval.error = -1
        except:
            retval.error = -1

        return retval

    def verify_user(self):
        retval = False
        print(
            "\nThe "
            + self.rest_user
            + " account will be used to communicate with Elastic during the upgrade process."
        )

        # If password was not given to class then need to prompt for it
        if self.rest_passwd is None:
            passprompt = "Enter the password for " + self.rest_user + ": "
            self.rest_passwd = getpass.getpass(prompt=passprompt)

        # print "User:", self.rest_user, " Password: ", self.rest_passwd

        result = self.get_restdata("_cluster/health?pretty")
        if (
            result.error == 0 and "status" in result.value.keys()
        ):  # Verify that nodes key exists
            if result.value["status"] == "green":
                print("Cluster status green, proceeding with upgrade...")
                retval = True
            elif self.force == True:
                print("Force Upgrade option detected, proceeding with upgrade...")
                retval = True
            else:
                print(
                    "\nCluster status is NOT green, check cluster and return to green before upgrading node"
                )
        else:
            print(
                "\nUnable to communicate with Elastic Cluster",
                result.errorStr,
                result.error,
            )

        return retval

    def prepare_for_upgrade(self):
        print("Preparing for upgrade...")
        retval = False
        reqdata = '{ "persistent": {"cluster.routing.allocation.enable": "primaries" }}'
        result = self.put_restdata("_cluster/settings", reqdata)

        if result.error == 0:
            if result.value["acknowledged"]:
                result = self.post_restdata("_flush")
                if result.error == 0:
                    result = self.post_restdata("_ml/set_upgrade_mode?enabled=true")
                    print("halted ml jobs")
                    if result.error == 0:
                        if result.value["acknowledged"]:
                            retval = True
                        else:
                            print("Unable to halt machine learning jobs.")
                    else:
                        print(
                            "Unable to communicate with Elastic Cluster, Flush synced failed",
                            result.errorStr,
                            result.error,
                        )
                else:
                    print(
                        "Unable to communicate with Elastic Cluster, Flush synced failed",
                        result.errorStr,
                        result.error,
                    )
                    exit()
            else:
                print("Disable allocation not acknoledged")
        else:
            print("Unable to disable allocation.")

        return retval

    def enable_allocation(self):
        retval = False
        reqdata = '{ "persistent": {"cluster.routing.allocation.enable": null }}'
        result = self.put_restdata("_cluster/settings", reqdata)

        if result.error == 0:
            if result.value["acknowledged"]:
                retval = True
        else:
            print("Unable to re-enable allocation.")

        return retval

    def execute_upgrade(self):
        if self.verify_user():
            if self.prepare_for_upgrade():
                print("Stop Elasticsearch to preform upgrade...")
                if os.system("systemctl stop elasticsearch") == 0:
                    print("Upgrading Elasticsearch...")
                    if os.system("yum -y upgrade elasticsearch") == 0:

                        # ensure file permissions after upgrade
                        uid = pwd.getpwnam(self.host[1:3] + "_elastic.svc").pw_uid
                        os.chown("/var/lib/elasticsearch", uid, -1)
                        os.chown("/var/log/elasticsearch", uid, -1)
                        os.chown("/etc/elasticsearch", uid, -1)

                        # Creates the elastic.conf file with proper account permissions
                        with open(
                            "/usr/lib/tmpfiles.d/elasticsearch.conf", "w"
                        ) as file:
                            file.write(
                                "d    /var/run/elasticsearch    0755 "
                                + (self.host)[1:3]
                                + "_elastic.svc elasticsearch - -"
                            )

                        print("Restarting Elasticsearch...")
                        os.system("systemctl daemon-reload")
                        if os.system("systemctl start elasticsearch") == 0:
                            print("Waiting for node to recover...")
                            time.sleep(30)

                            while not self.enable_allocation():
                                print("Waiting for successful allocation enable...")
                                time.sleep(5)

                            while True:
                                result = self.get_restdata("_cluster/health?pretty")
                                if (
                                    result.error == 0
                                    and "status" in result.value.keys()
                                ):
                                    if result.value["status"] == "green":
                                        print(
                                            "\nUpgrade for this node complete, continue with next node."
                                        )
                                        break
                                    else:
                                        sys.stdout.write(".")
                                        sys.stdout.flush()
                                else:
                                    sys.stdout.write("*")
                                    sys.stdout.flush()

                                time.sleep(10)
                        else:
                            print("Unable to start elasticsearch service...")
                    else:
                        print("yum upgrade did not complete successfully, Aborting...")
                else:
                    print("Unable to stop elasticsearch, Aborting...")
            else:
                print("Unable to prepare Elastic for upgrade, Aborting...")

    def update_yum(self):
        if os.system("yum -q clean all") == 0:
            print("Performed Yum Clean all...")


def main(argv):
    argv = sys.argv[1:]
    user = None
    passwd = None
    force = False

    try:
        opts, args = getopt.getopt(argv, "u:p:fh")
    except:
        print("Error getting ops...")
        exit()

    for opt, arg in opts:
        if opt == "-u":
            user = arg
        elif opt == "-p":
            passwd = arg
        elif opt == "-f":
            force = True
        elif opt == "-h":
            print("Usage: Upgrade -u <user> -p <passwd> -f")
            print(
                " <user> used for accessing elasticsearch, if not specified logged in user will be used"
            )
            print(
                " <passwd> password for specified user or logged in user if -u not specified"
            )
            print(
                " Note: If passwd is not specified the user will be prompted to enter it"
            )
            print("")
            print(" Note: -f forces an upgrade if the cluster cannot return to green")
            print("  to pass -f from upgrade_node: add -s -- -f to bash command")
            print(
                "curl -s -k https://xxsu01ro01.`hostname -d`/yum/elastic/install/upgrade_node.sh | bash -s -- -f"
            )
            exit()

    ses = Upgrade(user, passwd, force)
    ses.update_yum()
    ses.execute_upgrade()


if __name__ == "__main__":
    main(sys.argv[1:])
#################################################################################
#
# 			                    Unclassified
#
#################################################################################
