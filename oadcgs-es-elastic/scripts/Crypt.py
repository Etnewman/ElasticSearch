# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class used to encrypt/decrypt strings
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: Crypt.py
#
# Location: /etc/logstash/scripts
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Steve Truxal/Gary McKenzie, 2021-03-11: Original Version
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
# Frequency: Utility used by other classes when necessary
#
# Information Security Authorization
# ACC/A26 IA Approval: year-mm-dd, Name, ACC ISSE
#
# Lead System Engineering Authorization
# AF-DCGS LSE Approval: year-mm-dd, Name, AF-DCGS/AO
#
###########################################################################
#
import warnings

warnings.filterwarnings(
    "ignore", ".*deprecated in cryptography.*",
)

from cryptography.fernet import Fernet
import sys


class Crypt(object):
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(Crypt, cls).__new__(cls)
            # Put any initialization here.
            # Place generate key string in between the single - do not copy b' ' portion of the bytes
            cls.key = bytes(
                str("0_aejgPUBwLrfqQc427yz4bExmO6UCa6UfetFltr5lM=").encode("utf-8")
            )

            # Set suite variable to the decryption key
            cls.cipher_suite = Fernet(cls.key)
        return cls._instance

    def generate_key():
        # Run the module only if you need to generate a new key
        # - the new key will be needed to encrypt/decrypt all strings going forward
        encrypt_key = Fernet.generate_key()
        print(encrypt_key)

    def encode(self, passwd):

        # Convert string into binary to be used with encryption
        b_pass = bytes(str(passwd).encode("utf-8"))

        # Encrypts the username and passwords
        cipher_pass = self.cipher_suite.encrypt(b_pass)

        return cipher_pass.decode("utf-8")

    def decode(self, passwd):
        # Convert to bytes object
        passwd = bytes(passwd, "utf-8")

        # decrypting encrypted data
        b_uncipher_pass = self.cipher_suite.decrypt(passwd)

        return b_uncipher_pass.decode("utf-8")


def main():

    args = sys.argv[1:]
    if args[0] == "-e":
        print(Crypt().encode(args[1]))
    else:
        print(Crypt().decode(args[1]))


if __name__ == "__main__":
    main()
#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
