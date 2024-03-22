# -*- coding: utf-8 -*-
from elasticsearch import Elasticsearch
from ssl import create_default_context
from Crypt import Crypt
from threading import Thread, Lock
import constants
import subprocess
from datetime import datetime, timedelta
import time


class Singleton(type):
    _instances = {}

    _lock: Lock = Lock()

    def __call__(cls, *args, **kwargs):
        with cls._lock:
            if cls not in cls._instances:
                instance = super().__call__(*args, **kwargs)
                cls._instances[cls] = instance
        return cls._instances[cls]


class ElasticConnection(metaclass=Singleton):
    def __init__(self):
        try:
            with open(constants.QUERIER_DAT, "r") as pwfile:
                rawdata = pwfile.read().replace("\n", "")
                data = rawdata.split(":")
                self.quser = data[0]
                self.qpasswd = Crypt().decode(data[1])
        except:
            print(
                "Fatal Error: Could not retreive password from",
                constants.QUERIER_DAT,
                " for access to Elasticsearch",
            )
            exit()

        self.context = create_default_context(cafile="/etc/logstash/certs/cachain.pem")

        ### get the primary/secondary cluster domains ###
        try:
            values = {}
            with open(constants.CLUSTER_SITES, "r") as clusterfile:
                for line in clusterfile:
                    label, value = line.strip().split(":")
                    values[label] = value

            self.primary_cluster_domain = values.get("PRIMARY")
            try:
                self.secondary_cluster_domain = values.get("SECONDARY")
            except:
                print("No secondary cluster present.")
        except:
            print("Cannot read cluster location from file, setting to ech as default.")
            self.primary_cluster_domain = "ech"

        ### get logstash outputs and put them in an array ###
        output_values = []
        with open(constants.CLUSTER_OUTPUTS, "r") as outputfile:
            for line in outputfile:
                label, value = line.strip().split(":")
                if label.startswith("OUTPUT"):
                    output_values.append(value)

        ### build primary_hosts and secondary_hosts arrays ###
        self.primary_hosts = []
        self.secondary_hosts = []
        for val in output_values:
            self.primary_hosts.append(
                "https://" + val + "." + self.primary_cluster_domain + ":9200"
            )
            try:
                self.secondary_hosts.append(
                    "https://" + val + "." + self.secondary_cluster_domain + ":9200"
                )
            except:
                print("No secondary cluster present.")

        # create initial connection
        self.es = Elasticsearch(
            self.primary_hosts[0],
            http_auth=(self.quser, self.qpasswd),
            ssl_context=self.context,
        )

        # flag that tracks if we are disconnected from primary cluster (ech) or not
        self.primary_disconnect = False

        self.disconnect_timer = False

        self.disconnect_starttime = datetime.now()

        # check if theres a secondary cluster defined in cluster sites file
        self.secondary_cluster_present = False
        with open(constants.CLUSTER_SITES, "r") as f:
            for line in f:
                if "SECONDARY" in line:
                    self.secondary_cluster_present = True

    def check_cluster_connection(self, try_again):
        for host in self.primary_hosts:
            try:
                self.es = Elasticsearch(
                    host, http_auth=(self.quser, self.qpasswd), ssl_context=self.context
                )
                self.es.info()
                try_again = True
                self.primary_disconnect = False
                self.disconnect_timer = False
                return try_again
            except:
                print("Unable to connect to " + host)

        if self.secondary_cluster_present:
            if not self.primary_disconnect and not self.disconnect_timer:
                print("Starting disconnect timer...")
                self.primary_disconnect = True
                self.disconnect_timer = True
                self.disconnect_starttime = datetime.now()
                try_again = False

            elif self.primary_disconnect and self.disconnect_timer:
                timer = datetime.now() - self.disconnect_starttime
                if timer >= timedelta(minutes=constants.DISCONNECT_THRESHOLD):
                    print("Switching to secondary cluster...")
                    try_again = self.switch_cluster("secondary", self.secondary_hosts)

            return try_again

    def check_primary_cluster(self):
        if self.primary_disconnect:
            for host in self.primary_hosts:
                try:
                    es = Elasticsearch(
                        host,
                        http_auth=(self.quser, self.qpasswd),
                        ssl_context=self.context,
                    )
                    es.info()
                    print("Switching to primary cluster...")
                    self.switch_cluster("primary", self.primary_hosts)
                    self.primary_disconnect = False
                    self.disconnect_timer = False
                    break
                except:
                    pass

    def switch_cluster(self, cluster, hosts):
        try_again = True

        # Try to switch to the cluster, if we can't talk to it, exit
        can_connect = False
        for host in hosts:
            try:
                self.es = Elasticsearch(
                    host, http_auth=(self.quser, self.qpasswd), ssl_context=self.context
                )
                self.es.info()
                can_connect = True
                break
            except:
                print("Cannot connect to host" + host)

        if not can_connect:
            print("Unable to connect to secondary cluster...")
            try_again = False
            return try_again

        # switch cluster outputs in /etc/sysconfig/logstash
        if cluster == "primary":
            self.replace(
                constants.SYSCONFIG_FILE,
                self.secondary_cluster_domain,
                self.primary_cluster_domain,
            )
        else:
            self.replace(
                constants.SYSCONFIG_FILE,
                self.primary_cluster_domain,
                self.secondary_cluster_domain,
            )

        # restart logstash
        start_logstash = self.shutdown("java")
        if start_logstash:
            subprocess.run(["systemctl", "start", "logstash.service"], check=True)

        return try_again

    def sql_query(self, query):
        # query heartbeat data in the querier
        self.check_primary_cluster()
        capture = self.es.sql.query(body={"query": query})
        return capture

    def replace(self, filename, old, new):
        with open(filename, "r+") as file:
            lines = file.readlines()

        modified_lines = [line.replace(old, new) for line in lines]

        with open(filename, "w") as file:
            file.writelines(modified_lines)

    def shutdown(self, process_name):
        try:
            pid = int(subprocess.check_output(["pgrep", "-o", process_name]))
            start_logstash = False
            # send SIGKILL to process
            subprocess.run(["kill", "-9", str(pid)])

            # check that process is dead
            try:
                subprocess.check_output(["kill", "-0", str(pid)])
                print("Logstash not terminated")
                start_logstash = False
                return start_logstash
            except subprocess.CalledProcessError:
                print("Logstash process terminated")
                start_logstash = True
                return start_logstash
        except subprocess.CalledProcessError:
            print("Logstash process not found")
            return start_logstash

    def switch_secondary(self):
        self.es = Elasticsearch(
            self.secondary_hosts[0],
            http_auth=(self.quser, self.qpasswd),
            ssl_context=self.context,
        )

    def get_cluster_domains(self):
        if self.secondary_cluster_present:
            return self.primary_cluster_domain, self.secondary_cluster_domain
        else:
            return self.primary_cluster_domain
