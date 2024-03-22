################################### Unclassified ###################################

AN-GSQ-272 v6.1 2021-03-08 README FILE

Title: Elastic install directory contents

RFC Tracking #: CR-2020-OADCGS-086 (Initial Elasticsearch install of version 7.9.1)
                CR-2021-OADCGS-078 (Upgrade to version 7.12.1)
                CR-2021-OADCGS-020 (Upgrade to version 7.16.3)

Purpose: Scripts in this directory are used during the installation/upgrade of Elasticsearch, Logstash
         and Kibana onto the DCGS system.

Project/Function:  ElasticSearch
         CR-2020-OADCGS-086 - See "ES-018-Elastic Logging and Aggregation Cluster(ELAC)-System Installation Instructions" for more details.
         CR-2021-OADCGS-078 - See "ES-018-Elastic Logging and Aggregation Cluster(ELAC)-Upgrade to 7.12.1 Instructions" for more details.
         CR-2022-OADCGS-020 - See "ES-018-Elastic Logging and Aggregation Cluster(ELAC)-Upgrade to 7.16.3 Instructions" for more details.

Elastic Release Package contents:
*** Scripts, Data Files and Directories used during install of Elastic 7.9.1 ***
  - README.pdf                  (this file) is required for all scripts
  - add_pipeline.sh             Add a pipeline supplied by an external source
  - bootstrap_indexes.sh        Bootstraps the initial indexes
  - installElasticNode.sh       Elastic node install/upgrade script
  - installKibana.sh            Installs a Kibana instance
  - installLogstash.sh          Installs a Logstash node
  - load_auditsetting.sh        Loads audit settings for Elastic
  - load_filebeat_pipelines.sh  Installs Filebeat ingest pipelines into Elastic
  - load_ILMPolicy.sh           Loads the default Index Lifetime Management policy into Elastic
  - load_objects.sh             Loads spaces and saved objects into Elastic
  - load_pipelines.sh           Loads ESS Logstash Centralized pipelines into Elastic
  - load_role_mappings.sh       Loads Elastic to AD role mappings
  - load_roles.sh               Loads Kibana roles into Elastic
  - load_templates.sh           Installs templates for ES datatypes into Elastic
  - make_elastic_csrs.sh        Creates Public Key Infrastructure (PKI) req, keys, and Certificate Signing Requests (CSRs) for Elastic nodes
  - make_logstash_csr.sh        Creates PKI req, keys, and CSRs for Logstash instances
  - updateLicense.sh            loads elasticLicense.json into Elastic

Data Files
  - elasticLicense.json         Valid license file for Elastic
  - elasticsearch.keystore      contains initial bootstrap password for new clusters

Directories
  - certs                       Elastic/Logstash certificates are staged here for use during installation
      files: README,elastic_cachain.pem

  - dictionaries                dictionarys loaded onto Logstash instances are placed here
      files: mcafee_eventids.yml, windows_ids.yml

  - jdbc                        the jdbc jar file needed for Logstash is located here
      files: mssql-jdbc-7.2.2.jre8.jar

  - pipelines                   pipelines that are to be loaded into Kibana
      files: esp_filebeat, esp_hbss_syslog, esp_heartbeat, esp_linux_syslog,
             esp_loginsight, esp_metricbeat, esp_sccm_database, esp_sqlServer_stats, esp_winlogbeat

  - templates                   templates that are to be loaded into Kibana
      files: Default-Space-Objects.ndjson, est_dcgs_base_template, est_hbss-syslog,
              est_idm-template, est_linux-syslog, est_loginsight, est_sccmdb,
             est_sqlserver

*** Scripts, Data Files and Directories used during upgrades ***
  - bootstrap_indexes.sh 		Ensure alias exists for all indexes
  - installCurator.sh			Installs and configures curator and archiving configurations
  - installElasticDataCollector.sh 	Installs elastic data collector on a Logstash instance
  - installMetricbeatkeystore.sh	Installs and configures metricbeat user for monitoring
  - load_7.12_objects.sh 		Loads all 7.12 dashboards/visuals and other objects into Kibana
  - load_beats_db.sh 			Loads beats version monitoring dashboard into Kibana
  - load_templates.sh 		Adds new 7.12 templates into  Elastic
  - load_sitebased_pipelines.sh         Loads site based pipelines into Kibana
  - remove_7.9.1_objects.sh		Removes dashboards/visuals that were loaded during 7.9.1 install
  - update_auditsettings.sh		updates audit settings for new 7.12 users
  - update_filebeat_pipelines.sh	Updates pipelines for new filebeat version
  - update_logstash_pipelines.sh 	Updates logstash pipelines into Kibana
  - upgrade.py 				python script used by upgrade_nodes.sh
  - upgrade_logstash.sh			Upgrades a Logstash Instance
  - upgrade_nodes.sh 			Upgrade an Elasticsearch node
  - sites.yml - mapping for site numbers and names

Directories
  - certs-empty
     This is the original “certs” directory that was include for the 7.9.1 install.  It has been
     renamed to ensure nothing is changed in your working “certs” directory.

  - pipelines
       files: esp_arcsight_udp, esp_auditbeat, esp_hbss_syslog, esp_heartbeat, esp_loginsight, esp_sqlServer_stats,
                      esp_idm_database, esp_sccm_database, esp_winlogbeat, esp_filebeat, esp_linux_syslog, esp_metricbeat,
                      esp_filebeat-logstash, esp_filebeat-syslog, esp_eracent_database, esp_hbss-metrics,
                      esp_puppet_database
  -templates
      Index:
        esti_catalyst, esti_datadomain, esti_eracent, esti_fc6xx, esti_fx2, esti_hbss-metrics,
        esti_hbss-syslog, esti_healthdata, esti_idm, esti_isilon, esti_nexus5k, esti_puppet, esti_r6xx, esti_sccmdb, esti_sqlserver, esti_syslog, esti_vsphere, esti_xtreamio

        7.16.3 Specific: esti_filebeat-7.16.3, esti_heartbeat-7.16.3, esti_winlogb3eat-7.16.3

      component:
        estc_ciscoswitch-mappings, estc_datadomain-mappings, estc_dcgs_defaults,
        estc_dellidrac-mappings, estc_eracent-mappings, estc_fx2-mappings, estc_hbss-metrics-mappings,
        estc_hbss-syslog-mappings, estc_healthdata-mappings, estc_idm-mappings, estc_isilon-mappings, estc_puppet-mappings, estc_sccmdb-mappings,
        estc_sqlserver-mappings, estc_vsphere-mappings, estc_xtremio-mappings

        7.16.3 Specific: estc_filebeat-7.16.3-mappings, estc_heartbeat-7.16.3-mappings, estc_winlogbeat-7.16.3-mappings,
                         estc_metricbeat-7.16.3-mappings

  - artifacts                   Artifacts used during installation
      files: savedObjects_7.12.ndjson, beat_versions_db.ndjson, elasticDataCollector.service, device_mibs.tar,
      elasticDataCollector.tar, curatorConfig.tar

  - dictionaries                dictionarys loaded onto Logstash instances are placed here
      files: mcafee_eventids.yml, windows_ids.yml, sccm_message_ids.yml
  - jdbc                        the jdbc jar file needed for Logstash is located here
      files: mssql-jdbc-7.2.2.jre8.jar, postgresql-42.3.1.jar

INSTALLATION INSTRUCTIONS

CR-2020-OADCGS-086 - See "ES-018-Elastic Logging and Aggregation Cluster(ELAC)-System Installation Instructions" for more details.
CR-2021-OADCGS-078 - See "ES-018-Elastic Logging and Aggregation Cluster(ELAC)-Upgrade to 7.12.1 Instructions" for more details.
CR-2022-OADCGS-020 - See "ES-018-Elastic Logging and Aggregation Cluster(ELAC)-Upgrade to 7.16.3 Instructions" for more details.

FUNCTIONAL VERIFICATION STEPS

CR-2020-OADCGS-086 - See "ES-023-Elastic-Elastic 7.9.1 Installation Test Report"
CR-2021-OADCGS-078 - See "ES-023-Elastic-Elastic 7.12.1 Installation Test Report"
CR-2022-OADCGS-020 - See "ES-023-Elastic-Elastic 7.16.3 Installation Test Report"


################################### Unclassified ###################################
