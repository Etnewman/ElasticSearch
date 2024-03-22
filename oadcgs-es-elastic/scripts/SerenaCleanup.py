# -*- coding: utf-8 -*-
# 			 	           Unclassified
#
#########################################################################
############ AN-GSQ-272 SCRIPT HEADER VERSION 6.1 2021.03.08 ############
#
# Purpose: This class cleans up closed Serena incident tickets
#
# Tracking #: CR-2021-OADCGS-035
#
# File name: SerenaCleanup.py
#
# Location: /etc/logstash/scripts
#
# Version: 1.0
#
# Revisions: Provide version history to include version number,
#            applicable Tracking, Author’s Name, ate it was revised,
#            Explain what was changed.
#   version, RFC, Author’s name, date (yyyy-mm-dd): comments
#   v1.00, CR-2021-OADCGS-035, Robert Williamson, 2022-09-23: Original Version
#
# Site/System: All Sites where Logstash is installed
#
# Deficiency: N/A
#
# Use: This class runs once a day to cleanup closed Serena Tickets
#
# Users: Not for use by users.
#
# DAC Setting: 755 root root
#
# Frequency: runs daily in cron.daily
#
# Information Security Authorization
# ACC/A26 IA Approval: year-mm-dd, Name, ACC ISSE
#
# Lead System Engineering Authorization
# AF-DCGS LSE Approval: year-mm-dd, Name, AF-DCGS/AO
#
###########################################################################
#
from ElasticConnection import ElasticConnection


class SerenaCleanup:

    # Constructor
    def __init__(self):
        self.conn = ElasticConnection()

        self.cleanup_query = {"query": {"term": {"active_inactive": "inactive"}}}

    # Method: cleanup - Deletes inactive tickets from the Serena index
    #
    # Parameters:
    #   None
    # Returns:
    #   None
    def cleanup(self):
        self.conn.es.delete_by_query(
            index="dcgs-db_serena-iaas-ent", body=self.cleanup_query
        )


def main():
    cleaner = SerenaCleanup()
    cleaner.cleanup()


if __name__ == "__main__":
    main()

#################################################################################
#
# 			 	                  Unclassified
#
#################################################################################
