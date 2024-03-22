All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 2.1.38 (2024-02-14)

Add updated documents to release

### Added

- ES-24 - Elastic - Elastic System Administrator Guide.docx
- ES-24-Elastic-Elasticsearch_System_Administrator_Guide.pdf
- RFC - Elaticsaerch - 8.11.3 Upgrade Instructions.docx
- RFC-Elasticsearch-8.11.3_Upgrade_Instructions.pdf

## 2.1.37 (2023-02-08)

Redline updates for issues found during testing and the addition of collection
DLP data from the elasticDataCollector

### Changed

- upgrade_logstash.sh - Add missing "-k"s and export logstash environment
  variables
- esw_current-health-updater - Only update recored that were updated by Logstash
- ElasticConnection.py - Updates to fix issues with auto failover
- esp_loginsight - Send data to new dcgs-syslog_loginsight-iaas-ent index to
  allow seperation of data and drop non-audit data
- bootstrap_site_specific.sh - updated for new dcgs-syslog_loginsight-iaas-ent
  index and to ensure an is_write_index exists for each alias
- esti_hbss-dlp - index template missing index pattern
- esti_loginsight_syslog - index template not formatted correctly
- load_SLM_Policy.sh - Updated to not archive cold, frozen or CCR follower
  indexes
- constants.py - Added DLP constants
- elasticDataCollector.py - Added ability to create DLP thread
- Device.py - Added DLP type and get_device_types method. Also added updates to
  support future Aruba devices.
- configurator.py - GUI has been refactored to be object oriented and to support
  both DLP and future Aruba devices.
- esp_filebeat-logstash - updated depricated settings and also added support for
  DLP data ingestion
- estc_healthdata-mappings - Updates for new container fields
- esp_metricbeat - Add DCGS_Site-Name to app-host documents
- elasticInfo.py - Additions for DLP class

### Added

- Add missing 8.11.3 logstash-slowlog ingest pipelines
- DLP.py - New class in data collector for DLP data
- guiConstants.py - new file to hold contansts only used in GUI

### Removed

- All 8.11.1 ingest templates

## 2.1.36 (2023-12-19)

Adds artifacts related to the Elasticsearch upgrade to version 8.11.3. Includes
ingest pipelines and component templates.

### Added

- 8.11.3 Filebeat and Winlogbeat ingest pipelines
- estc_filebeat-8.11.3-mappings
- estc_heartbeat-8.11.3-mappings
- estc_metricbeat-8.11.3-mappings
- estc_winlogbeat-8.11.3-mappings
- esti_filbeat-8.11.3
- esti_heartbeat-8.11.3
- esti_winlogbeat-8.11.3

## 2.1.35 (2023-12-15)

Fixes found during testing final updated for 8.11.1

### Changed

- Updates to load_objects.sh to work on WCH cluster

## 2.1.34 (2023-12-15)

This version brings final updates for the 8.11.1 release to MTE

### Changed

- estc_winlogbeat-settings - Updated lifecycle name
- escw_current-healthdata-stale-state - Modifed Updated_By to WATHCHER-STALE
- esw_current-healthdata-updater - modified query to look for data updated by
  LOGSTASH or WATHER-STALE that is not older than 7 days
- bootstrap_indexes.sh - Added section to ensure non-timeseries indexes exist in
  cluster
- create_spaces.sh - Allow to be run on both ECH and WCH clusters
- installElasticDataCollector.sh - updated logic to assume secondary cluster if
  primary is ech and other updates to allow execution on multiple clusters
- installElasticNode.sh - updates for CCR and Frozen tier
- installKibana.sh - updates for 7 node REL cluster
- installMetricbeatkeystore.sh - updates to allow script to work on WCH cluster
- installWatchers.sh - updates to install auto detect when 2nd cluster is
  available for additional watchers
- load_ILM_Policies - Script renamed and default-ss directory name updated to be
  consistent with others
- load_auditsettings.sh - Add exclusions for new logstash users ls_admin and
  ls_internal
- make_elastic_csrs.sh - Update to allow creation of CSRs for WCH cluster
- updateLicense.sh - updated to pull correct license from licenses directory of
  install directory
- update_default_space - updated to work on WCH cluster
- update_ingest_pipelines.sh - updated to allow parameter to be passed
  specifying version of pipelines to be added to cluster
- update_kibana_settings.sh - updated to work on WCH Cluster
- update_lifecycle.sh - Script renamed and winlogbeat lifecycle name updated
- upgrade_node.sh - initial_master_nodes setting removed as this does not apply
  to existing clusters
- Cleanup.py - updated to execute queries on both clusters (if 2nd cluster)
- ElasticConnection.py - New methods added to allow manual request to swtich to
  secondary cluster
- ThreadInfo.py - Minor gramatical update

### Added

- Added 8.6.2 ingest pipelines for Kibana data
  - filebeat-8.6.2-kibana-audit-pipeline
  - filebeat-8.6.2-kibana-audit-pipeline-json
  - filebeat-8.6.2-kibana-log-pipeline
  - filebeat-8.6.2-kibana-log-pipeline-7
  - filebeat-8.6.2-kibana-log-pip4eline-ecs

## 2.1.33 (2023-12-15)

This version updates the Baseline space. It updates the ART integrations for
Ashes, ECP, Guardian, MAAS, Render, SOAESB, SOCET, Unicorn, and Xplorer.

### Changed

- Baseline-Space-Objects.ndjson:
  - IAAS-ES-FC6XX - Updated Navigation links.
  - IAAS-ES-Isilon - Update dashboard.
  - IAAS-ES-BEATS - Update dashboard.
  - IAAS-ES-SYSTEM-Application - Updated dashboard.
  - IAAS-ES-FX2 - Update dashboard name.
  - IAAS-ES-Guardian - Renamed and moved to ART ndjson
  - IAAS-ES-RENDER - Renamed and moved to ART ndjson
  - Pipeline Confirmation Test - removed from space
  - IAAS-ES-Serena Incidents - removed from ndjson
  - IAAS-ES-KIBANA-User-Login.ndjson - New dashboard for monitoring Kibana Usage
    by users
- dcgs-ecp.ndjson - Rename file, update data view.
- dcgs-gxpxplorer.ndjson - Update times on dashboards, data view
- dcgs-maas.ndjson - Rename file, update data view.
- dcgs-soaesb.ndjson - Update data view.
- dcgs-socetgxp.ndjson - Update dashboards.
- dcgs-unicorn.ndjson - Fix dashboards.
- estc_ecp-mappings - Add fields.
- estc_maas_logs-mappings - Add fields.
- estc_unicorn-filebeat-mappings - Reformat, add fields.
- load_objects.sh - Update and add ndjson names; change curl to import into
  Baseline space.
- test_data/ECP/\* - Simplify test yml.
- test_data/GXPXplorer/\* - Simplify test yml.
- test_data/MAAS_Logs/\* - Simplify test yml.
- test_data/SOAESB/\* - Simplify test yml, rename test data.
- test_data/SocetGXP/\* - Simplify test yml, rename test data.

### Added

- dcgs-ashes.ndjson - New dashboard for Ashes.
- dcgs-guardian.ndjson - Moved out of default ndjson.
- dcgs-render.ndjson - Moved out of default ndjson.
- esp_filebeat - Add log.level check for Xplorer, remove unneeded fields from
  ECP.
- esp_filebeat-singleworker - Correct Render block; fic Socet and MAAS index
  names
- test_data/Guardian/\* - Add test yml & data
- test_data/Render/\* - Add test yml & data
- test_data/Unicorn/\* - Add test yml & data

## 2.1.32 (2023-12-14)

This change adds puppet.Reason for updated Puppet visuals

### Changed

- esp_linux_syslog - Add puppet.Reason keyword
- estc_syslog-mappings - Add puppet.Reason mapping

## 2.1.31 (2023-12-13)

This version updates the upgrade_logstash.sh script to allow communications with
both ECH and WCH clusters.

### Changed

- upgrade_logstash.sh - Update to add users 'ls_internal' and 'ls_admin', create
  ls_user.dat to store usernames and encrypted passwords.
- bootstrap_site_sepcific.sh - Modified to be called from upgrade_logstash.sh,
  and allow bootstrap for metricbeat 8.6.2 indexes
- installElasticDataCollector.sh - Update to work with 2 clusters
- esp_eracent_database - Update username and password
- esp_filebeat - Update username and password
- esp_filebeat-logstash - Update username and password
- esp_filebeat-singleworker - Update username and password
- esp_hss_dlp - Update username and password
- esp_hbss_dlp-via-connector - Update username and password
- esp_hbss_epo - Update username and password
- esp_hbss_metrics - Update username and password
- esp_heartbeat - Update username and password
- esp_idm_database - Update username and password
- esp_linux_syslog - Update username and password
- esp_loginsight - Update username and password
- esp_metricbeat - Update username and password
- esp_postgres - Update username and password
- esp_puppet_database - Update username and password
- esp_sccm database - Update username and password
- esp_serena_database - Update username and password
- esp_sqlServer_stats - Update username and password
- esp_syslog_tcp - Update username and password
- esp_syslog_udp - Update username and password
- esp_unicorn_database - Update username and password
- esp_winlogbeat - Update username and password

## 2.1.30 (2023-12-05)

This version modifies all scripts to utilize the satellite/capsule servers
instead of the legacy repo server.

### Changed

- activate_serena.sh - Replaced reposerver variables with fileloc
  (satellite/capsule)
- activate_unicorn.sh - Replaced reposerver variables with fileloc
  (satellite/capsule)
- create_spaces.sh - Replaced reposerver variables with fileloc
  (satellite/capsule)
- installCurator.sh - Replaced reposerver variables with fileloc
  (satellite/capsule)
- installElasticDataCollector.sh - Replaced reposerver variables with fileloc
  (satellite/capsule)
- installElasticNode.sh - Replaced reposerver variables with fileloc
  (satellite/capsule)
- installKibana.sh - Replaced reposerver variables with fileloc
  (satellite/capsule)
- installLogstash.sh - Replaced reposerver variables with fileloc
  (satellite/capsule)
- installMetricbeatkeystore.sh - Replaced reposerver variables with fileloc
  (satellite/capsule)
- installWatchers.sh - Replaced reposerver variables with fileloc
  (satellite/capsule)
- load_7.17_objects.sh - Replaced reposerver variables with fileloc
  (satellite/capsule)
- load_beats_db.sh - Replaced reposerver variables with fileloc
  (satellite/capsule)
- load_objects.sh - Replaced reposerver variables with fileloc
  (satellite/capsule)
- load_sitebased_pipelines.sh - Replaced reposerver variables with fileloc
  (satellite/capsule)
- load_templates.sh - Replaced reposerver variables with fileloc
  (satellite/capsule)
- updateLicense.sh - Replaced reposerver variables with fileloc
  (satellite/capsule)
- update_ingestpipelines.sh - Replaced reposerver variables with fileloc
  (satellite/capsule)
- update_logstashpipelines.sh - Replaced reposerver variables with fileloc
  (satellite/capsule)
- upgrade_logstash.sh - Replaced reposerver variables with fileloc
  (satellite/capsule)
- upgrade_node.sh - Replaced reposerver variables with fileloc
  (satellite/capsule)

## 2.1.29(2023-12-05)

This version updates the configuration of node roles during an upgrade adding
roles for cold, frozen and transform.

### Changed

- upgrade_node.sh - Update to allow for new node roles during upgrade

## 2.1.28(2023-12-05)

This version adds the Ashes ST integration package. It includes the Ashes
pipeline, index and component templates, and updates to required scripts.

### Changed

- bootstrap_indexes.sh - adds dcgs-filebeat-sr-ashes index to list of indexes to
  be bootstrapped
- load_templates.sh - adds esti_ashes index template and estc_ashes-mappings
  component template to list of templates to be loaded

### Added

- esp_ashes - pipeline to receive and process Ashes data
- esti_ashes - Ashes index template
- estc_ashes - Ashes component template

## 2.1.27 (2023-12-04)

This version contains the following bug fixes:

- Updates the AuditCheck to run every five minutes instead of every 24 hours
- Updated SCCM Monitoring template to remove looking for "IISADMIN" and "W3SVC"
- Corrects the SOCET and MAAS artifacts
- Pulled bootstapping section out of upgrade_logstash to be standalone script
  that can be run independently
- Removes a decode function from updatepasswd that was already added to Crypt
- Implement solution for not calculating utilization for VLANs

### Changed

- AuditCheck.py - Changed set_next_runtime from 86400 seconds, to 300.
- sc01.metricbeat.yml - Removed looking for "IISADMIN" and "W3SVC"
- dcgs-socetgxp.ndjson - Change agent.hostname and beat.hostname to host.name,
  correct Data View id.
- dcgs-unicorn.ndjson - Remove trailing newline (pre-commit check).
- dcgs-maas_logs.ndjson - Correct Data View id.
- bootstrap_indexes.sh - Correct MAAS index name.
- upgrade_logstash.sh - Removed bootstrapping, create alias sections, and delete
  old template section to create a standalone script
- updatepasswd.py - removed a duplicate .decode conflicting with Crypt.py
- CiscoSwitch.py - exclude switches with ifType of 'propVirtual' from
  utilization calculation
- bootstrap_indexes.sh - Add new esti_unparsable-syslog template
- load_templates.sh - Add new esti_unparsable-syslog template
- esp_linux_syslog - Update to change unparsable to unparsed
- esp_loginsight - Update to change unparsable to unparsed
- esti_current-healthdata - Remove ILM

### New

- boostrap_site_specific.sh added to run site specific bootstrapping
  independently
- esti_unparsable-syslog - Add for ILM

## 2.1.26 (2023-12-01)

This version adds a cold phase to the dcgs_default_policy and creates the
repository these indexes will be stored in.

### Changed

- load_ILM_Policy.sh - Update dcgs_default_policy to include a cold phase and
  create the repository to store them

## 2.1.25 (2023-12-01)

This version adds 8.11.1 Ingest Pipelines and Templates. Unused files are also
removed

### Changed

- install/ingest_pipelines/dcgs_ingest_pipeline_updates.txt - Add 8.11.1 changes
  and reformat whole document.

### New

- install/ingest*pipelines - add *-8.11.1-\_ files.
- install/templates - add estc*\*-8.11.1-mappings, estc_winlogbeat-settings, and
  esti*\*-8.11.1 files.
- devUtils/ingest-pipeline changes.txt - Describe what needs to be done to
  update out-of-the-box pipelines for a new Elastic version.

### Removed

The following files that are no longer used were removed

- 8.9.0 ingest pipelines
- 8.6.1 ingest pipelines
- est legacy templates

## 2.1.24 (2023-11-30)

This version adds the esw_healthdata-updater and updated associated data flow

### Added

- esw_healthdata-updater - This watcher will view all documents in
  current-healthdata follower index and update the current-healthdata local
  index if it notices that the document from the follower index was updated by
  Logstash.
- esw_failover-duplicate-doc - Not in use, will be for future examples of
  complicated aggregations in watchers.
- put_watcher.sh - Dev. Util., to test successful POST of Watcher
- get_watcher.sh - Dev. Util., to pull watcher from Elasticsearch

### Changed

- esp_metricbeat - Added app_event("updated_By", "LOGSTASH") for the new
  'updated_By' field
- esp_filebeat-logstash - Added 'updated_By': 'LOGSTASH' field
- estc_healthdata-mappings - Template for 'updated_By' field
- installWatchers.sh - Added healthdata watcher to list of watchers and logic to
  SED the watcher to determine which follower index to assign to
- esw_current-healthdata-stale-state - Changed index pattern to not contain
  wildcard, reformatted and added logic for more resiliency
- installElasticDataCollector.sh - changed name of Cleanup cron for usage
  elsewhere
- Cleanup.py - reformatted to be able to run multiple different delete queries

## 2.1.23 (2023-11-16)

This version incorporates ECP artifacts and updates install scripts.

### Changed

- esp_filebeat - Add ECP logic.
- bootstrap_indexes.sh - Add ECP to list
- load_objects.sh - Add ECP to list
- load_templates.sh - Add ECP to list
- inputs.txt - Add ECP_AutoRouterVM.yml, ECP_ServicesVM.yml, and
  ECP_Workstation.yml
- dcgs-unicorn.ndjson - Precheck removed trailing space.

### New

- geo-sensors-ecp.ndjson - Demo ECP dashboards to show data and fields.
- estc_ecp-mappings - ECP field mappings.
- esti_ecp - ECP index settings.
- ECP_AutoRouter.yml - Filebeat settings for ECP AutoRouter VMs.
- ECP_Services.yml - Filebeat settings for ECP Services VM.
- ECP_Workstation.yml - Filebeat settings for ECP Workstations.
- test_data/ECP/ECPTestData.log - Simple test data, to show data types.
- test_data/ECP/ECP_Sample_data.zip - All sample data provided by ECP team.
- test_data/ECP/ECP_Test.yml - Filebeat config to read test logs on test
  systems.

## 2.1.22 (2023-11-15)

This version finalizes the UNICORN integration

### Changed

- esti_unicorn-sql - Changed index pattern to match corresponding data view
- esp_filebeat - Added Unicorn Filter
- esp_filebeat-singleworker - Removed Unicorn Filter
- inputsByService.txt - Updated Services to match config rule ("app=config")

## 2.1.21 (2023-11-14)

This version updates the Elastic Data Collector code to handle automatic
Logstash failover should connection to the cluster be lost.

### Changed

- ElasticConnection.py - updated to handle automated logstash failover, methods
  added to handle failover, and utilize new clusterSites.dat and
  clusterOutputs.dat files.
- Querier.py - updated to trigger failover mechanism if hearbeat query cannot be
  completed successfully.
- constants.py - new constants added
- version.py - Data Collector version updated

## 2.1.20 (2023-11-13)

This version contains the following bug fixes:

- Gives app-host and group documents unique document_id’s by adding the
  app_cleanup.sh script to remove all documents affected by the
  esp_filebeat-logstash changes. Apps will now have a site number prepended.
- Adds udf to the array of filesystem.ignore_types to prevent monitoring issues.
- Updates the load_roles.sh script to remove the manage privilege and streamline
  others. It also updates the index privileges to remove manage.
- Updates the CiscoSwitch.sh script to compare Catalyst inlet/CPU temps to their
  corresponding constant.
- Fixes ElasticInfo.py so that it outputs to fields within an object.
- Marks “wu” (Workstation Unix) boxes as “Linux” in esp_linux_syslog pipeline.
- Creates way to determine if Logstash or Elasticsearch needs to be upgraded.
- Fixes FX2 symptoms showing “NONE symptom” when there are issues.
- Updates elasticsearch.yml for active directory authentication.
- Updates Data Collector to correct reference before assignment and formatting
  bugs.

### Changed

- esp_filebeat-logstash - Added SITENUM to app_overall, group, and datacollector
  id's
- all.module.system.yml - Added "udf" to the array of filesystem.ignore_types
- load_roles.sh - Removed manage, manage_watcher, and monitor_rollup. Added
  manage_logstash_pipelines, monitor, read_slm, and read_security. Removed index
  and manage index privileges from all indices.
- CiscoSwitch.sh - Swap constants for Catalyst inlet/CPU temps.
- esp_linux_syslog - adds “wu” (Workstation Unix) boxes as “Linux”
- ElasticInfo.py - Fixed so that output fields are within an object
- bootstrap_indexes.sh - change bsver variable to get running Elasticsearch
  version
- installLogstash.sh - change bsver variable to get running Logstash version
- load-templates.sh - change esver variable to get running Elasticsearch version
- update_ingest_pipelines.sh - change ver variable to get running Elasticsearch
  version
- update_kibana_settings.sh - change ver variable to get running Kibana version
- upgrade_logstash.sh - change bsver variable to get running Logstash version
- upgrade_node.sh - Changed to dynamically update elasticsearch.yml for active
  directory authentication
- DellIdrac.py - Added variable so that we don't get a null exception
- Watcher.py - Added a try catch block in case of malformed JSON data
- Fx2.py - moves check for symptom NONE

### New

- app_cleanup.sh - Ran after the new esp_filebeat-logstash pipeline has been
  loaded to remove old non-site-specific \_id's.

## 2.1.19 (2023-11-11)

This version adds Cross Cluster Replication

### Added

- load_CCR.sh - Configures Remote Clusters and bi-directional Cross Cluster
  Replication

## 2.1.18 (2023-11-2)

This version loads new ILM policy for certain indexes, rolls over existing
indexes to use searchable snapshots, and creates component templates and added
them to their corresponding index files for the transition to searchable
snapshot.

### Changed

- esti_db_postgres - added component template
- esti_hbss-epo - added component template
- esti_vsphere - added component template
- esti_winlogbeat-7.16.3 - added component template
- esti_winlogbeat-7.17.6 - added component template
- esti_winlogbeat-8.6.2 - added component template
- load_ILM_Policy.sh - changed to add syslog and audit_syslog component files
  dynamically to corresponding esti files
- load_ILM_Policy.sh - loads new ILM policy for dcgs_audits_syslog, dcgs_db,
  dcgs_hbss_epo, dcgs_syslog, dcgs_vsphere, and winlogbeat
- load_templates.sh - add new component templates

### Added

- estc_audits_syslog-settings - new component template for ILM policy
- estc_db-settings - new component template for ILM policy
- estc_hbss-epo-settings - new component template for ILM policy
- estc_syslog-settings - new component template for ILM policy
- estc_vsphere-settings - new component template for ILM policy
- estc_winlogbeat-settings - new component template for ILM policy
- indextoSearchableSnapshot.sh - change index setting of existing indexes to use
  searchable snapshots

## 2.1.17 (2023-10-16)

The version adds the ingest pipelines for Kibana auditing data to the baseline.
The version also updates the pull_ingest_pipelines.sh and
update_ingest_pipelines.sh scripts to include these ingest pipelines.

### Changed

- pull_ingest_pipelines.sh - Add kibana-audit-pipeline,
  kibana-audit-pipeline-json, kibana-log-pipeline, kibana-log-pipeline-7,
  kibana-log-pipeline-ecs
- update_ingest_pipelines.sh - Add kibana-audit-pipeline,
  kibana-audit-pipeline-json, kibana-log-pipeline, kibana-log-pipeline-7,
  kibana-log-pipeline-ecs

### Added

- filebeat-"${ver}"-kibana-audit-pipeline
- filebeat-"${ver}"-kibana-audit-pipeline-json
- filebeat-"${ver}"-kibana-log-pipeline
- filebeat-"${ver}"-kibana-log-pipeline-7
- filebeat-"${ver}"-kibana-log-pipeline-ecs

## 2.1.16 (2023-10-13)

This version updates the RequestHandler.py class to return better formatted and
more detailed API calls.

### Changed

- RequestHandler.py - Adds "pretty printing" to all API calls by default
- version.py - Updated to new version

## 2.1.15 (2023-08-11)

This version changes the Default space to Default-Deprecated. Adds a new
Baseline space that will hold out latest Visualizations.

### Changed

- load_roles.sh - Add default-deprecated to dcgs_kibana_user

### Added

- update_default_space.sh - updates Default space and adds Baseline space

## 2.1.14 (2023-08-02)

This version updates the Elasticsearch python API to the current version 8.9.0
and updates the ElasticConnection.py class to work with the new version.

### Changed

- ElasticConnection.py - updates code to work with new API version
- installElasticDataCollector - adds new dependencies to be installed
- version.py - updates Data Collector version
- constants.py - adds new constant for Elastic connection node

## 2.1.13 (2023-07-21)

This version adds loginsight index and further refines which index audits are
placed

### Changed

- esp_loginsight - Modify pipeline for new loginsight index
- bootstrap_indexes.sh - Add new loginsight index
- load_ILM_Policy.sh - Add 7 day ILM policy
- load_templates.sh - Add pipeline for new loginsight index
- update_logstash_pipelines.sh - Add pipeline for new loginsight index

### Added

- estc_loginsight_syslog-mappings - New mappings to support loginsight index
- esti_loginsight_syslog - New index template to support loginsight index

## 2.1.12 (2023-07-17)

The version adds the pipelines syslog_tcp and syslog_udp and supporting files
(Duplicate of 2.0.41 - orignal merge into 8.6.2)

### Changed

- update_logstash_pipelines.sh - Add esp_syslog_udp and esp_syslog_tcp

### New

- esp_syslog_tcp - tcp syslog pipeline
- esp_syslog_udp - udp syslog pipeline

## 2.1.11 (2023-07-21)

This version adds the ability for threads running in the Elastic Data Collector
to automatically restart themselves should they die. This version also adds a
new class ThreadInfo which holds the Data Collector threads and other
information.

### Changed

- Document.py - adds a new symptom, RESTARTING
- constants.py - adds new constants MAX_RESTARTS and TIME_THRESHOLD
- elasticDataCollector.py - adds ability for Data Collector threads to restart
  themselves and stores threads in new threadDict dictionary
- ElasticInfo.py - adds new methods to facilitate the automatic restart of
  threads
- version.py - updates Data Collector version

### Added

- ThreadInfo.py - class that holds information on Data Collector threads and
  related methods

## 2.1.10 (2023-07-17)

This version adds an app config file option to metricbeat.yml.

### Changed

- install_beats_windows.ps1 - Use existing process to insert code into
  metricbeat.yml for apps. Rather than config files in a subdirectory like
  filebeat, insert code into the 'apps' section of metricbeat.yml when it is
  copied to the host.

### Added

- example_config.app - Sample file for content to insert into metricbeat.yml.
- inputs.txt - Empty config file for metricbeat.

## 2.1.9 (2023-07-13)

This version tests and fixes any lingering issues from baselining the UNICORN
integration.

### Changed

- esp_filebeat-singleworker - Modified slightly so that Elastic can successfully
  put into logstash pipeline, fixed grok and time parse errors.
- esp_unicorn-database - Modified connection string such that installer can
  input HOSTNAME and DBNAME

### Added

- activate_unicorn.sh - Script that allows the installer to modify the UNICORN
  SQL DB pipeline to match their connection string.

## 2.1.8 (2023-05-23)

This version fixes some deprecations as a result of moving to elasticsearch 8.X.
In that, we removed the reporting_user mapping, and edited the elasticsearch.yml
to stop using the Monitor pluggin for monitor data. Finally, in the puppet repo,
we changed a classname from data to unifiedSearch in kibana.yml.

### Changed

- installElasticNode.sh - removed the monitor pluggin activation calls in the
  creation of the elasticsearch.yml file.
- load_role_mappings.sh - removed reporting_user from role mappings.
- upgrade_node.sh - removed deprecated monitoring section

### Added

- deprecation_update.sh - This script will fix various deprecation issues every
  release.

## 2.1.7 (2023-07-12)

This version contains the new component and index templates for logindata, as
well as, updates to the bootstrap_indexes.sh and load_templates.sh scripts. The
filebeat pipeline was updated to be able to process the logindata index

### Changed

- Added dcgs-logindata-iaas-ent to bootstrap_indexes.sh script
- Added esti_logindata template to the array in the load_templates.sh script
- Added estc_logindata-mappings to the array in the load_templates.sh script
- Updated esp_filebeat pipeline to process logindata index data

### New

- Added esti_logindata index template to the baseline
- Added estc_logindata-mappings component template to the baseline

## 2.1.6 (2023-06-27)

This version adds the UNICORN integration package.

### Added

- esp_unicorn_database - UNICORN SQL Pipeline to get SQL logs.
- estc_unicorn-filebeat-mappings - Component template for UNICORN filebeat
  config.
- estc_unicorn-sql-mappings - Component template for UNICORN SQL Connector.
- esti_unicorn-filebeat - Index template for UNICORN filebeat config.
- esti_unicorn-sql - Index template for UNICORN SQL Connector.
- unicorn.yml - Filebeat YML file for config.

### Changed

- esp_filebeat-singleworker - Added UNICORN section to pipeline.
- inputsByService.txt - Added UNICORN service.

## 2.1.5 (2023-06-27)

This version squashes Logstash Info messages in Logstash log

### Changed

- log4j2.properties.logstash - Change the message level from INFO to WARN for
  Logstash messages.

## 2.1.4 (2023-06-27)

This version creates a Cyber Ops space

### Changed

- create_spaces.sh - Create space "CyberOps"; add comment for creating site
  spaces; skip space creation is it already exists.

## 2.1.3 (2023-06-27)

This version update the logstash pipelines to add persisted queues and size the
queues

### Changed

- install/pipelines/esp_eracent_database - persisted queues and queue sizing
- install/pipelines/esp_filebeat - persisted queues and queue sizing
- install/pipelines/esp_filebeat-singleworker - persisted queues and queue
  sizing
- install/pipelines/esp_hbss_dlp - persisted queues and queue sizing
- install/pipelines/esp_hbss_epo - persisted queues and queue sizing
- install/pipelines/esp_idm_database - persisted queues and queue sizing
- install/pipelines/esp_linux_syslog - persisted queues and queue sizing
- install/pipelines/esp_loginsight - persisted queues and queue sizing
- install/pipelines/esp_puppet_database - persisted queues and queue sizing
- install/pipelines/esp_sccm_database - persisted queues and queue sizing
- install/pipelines/esp_winlogbeat - persisted queues and queue sizing

## 2.1.2 (2023-06-26)

This version sets all label fields to keyword

### Changed

- estc_dcgs_app_defaults - Change dynamic mapping so all types are mapped as
  keyword in label and container.label fields.

## 2.1.1 (2023-06-16)

This version add the hbss data loss prevention(dlp) data

### Changed

- install/installElasticDataCollector.sh - Added install ownership and
  permissions for DLP
- install/templates/estc_hbss-epo-mappings - New mappings for DLP events
- install/pipelines/get_pipelines.sh - Updated to remove /r
- install/update_logstash_pipelines.sh - Added esp_hbss_dlp pipeline

## 2.1.0 (2023-06-16)

This verison adds spaces, roles, and role mappings for each DCGS site.

### Changed

- load_role_mappings.sh - Add dcgs_site_user to mapping for dcgs_kibana_user.
- load_roles.sh - Add empty role dcgs_site_user (filled in with enclave sites in
  create_spaces.sh); add reporting permissions to read-only roles; fix index
  pattern string.
- sites.yml - Change site names to format provided by DMC.

### New

- create_spaces.sh - Identifies what sites exist for this enclave and creates
  site spaces, site admin roles, and role mappings for each; adds read-only
  access to all sites to dcgs_site_user.

## 2.0.43 (2023-07-27)

This version brings the final update to the 8.6.2 release

### Changed

- upgrade_nodes.sh - Add missing -k to curl command

## 2.0.42 (2023-07-25)

Update from DSIL testing of 8.6.2

### Changed

- bootstrap_indexes.sh - bootstrap index to hold DLP data received from ArcSight
  connector
- load_templates.sh - Add new template for DLP data received from ArcSight
  connector
- update_logstash_pipelines.sh - Add pipeline to receive data from ArcSight
  connector
- templates/esti_hbss-dlp - New template for index holding data received from
  ArcSight connector
- pipelines/esp_hbss_dlp-via-connector - New pipeline to receive data from
  ArcSight connector
- pipelines/esp_eracent_database - persisted queues and queue sizing
- pipelines/esp_filebeat - persisted queues and queue sizing
- pipelines/esp_filebeat-singleworker - persisted queues and queue sizing
- pipelines/esp_hbss_dlp - persisted queues and queue sizing
- pipelines/esp_hbss_epo - persisted queues and queue sizing
- pipelines/esp_idm_database - persisted queues and queue sizing
- pipelines/esp_linux_syslog - persisted queues and queue sizing
- pipelines/esp_loginsight - persisted queues and queue sizing
- pipelines/esp_puppet_database - persisted queues and queue sizing
- pipelines/esp_sccm_database - persisted queues and queue sizing
- pipelines/esp_winlogbeat - persisted queues and queue sizing

### New

- licenses/OAH/AFDCGS-Production-HIGH-Expires-May-29-2024.json - Production
  License for High
- licenses/OAH/AFDCGS-NON_Production-HIGH-Expires-May-29-2024.json -
  Non-Production License for High
- licenses/OAL/AFDCGS-Production-LOW-Expires-May-29-2024.json - Production
  License for Low
- licenses/OAL/AFDCGS-NON_production-LOW-Expires-May-29-2024.json -
  Non-Production License for Low
- licenses/REL/AFDCGS-Production-REL-Expires-May-29-2024.json - Production
  License for REL
- licenses/REL/AFDCGS-NON_production-REL-Expires-May-29-2024.json -
  Non-Production License for REL
- IOS-XE_Add_DNS_and_Logstash.xml - Prime template for switch updates to send
  syslog to Logstash
- NX-OS_Add_DNS_and_Logstash.xml - Prime template for switch updates to send
  syslog to Logstash
- artifacts/ess/DeployArcSightMod.txt - Hashes for ESS artifacts
- artifacts/ess/DeployArcSightMod.zip - Zip containing artifacts for
  configuration of ArcSight connector on ESS to forward DLP events to Logstash
- docs/IAAS-018 - ESS - Temporary ArcSight Connector to Elastic Installation
  Instructions.docs - Install instructions to configure ArcSight connector on
  ESS to forward DLP events to Logstash
- artifacts/print_templates/Cisco_Prime_Logstash_Update_Templates.zip - Prime
  templates for sending data to Logstash
- docs/Prime_Updates.docx - Instructions on configuring Cisco Prime for sending
  switch syslog to Logstash
- dumpArcSightArchive.py - Initial script to extract contents of ArcSight
  archives
- estc_hbss-epo_dlp-mappings - Mappings for DLP data from ArcSight connector

## 2.0.41 (2023-07-14)

The version adds the pipelines syslog_tcp and syslog_udp and supporting files

### Changed

- update_logstash_pipelines.sh - Add esp_syslog_udp and esp_syslog_tcp

### New

- esp_syslog_tcp - tcp syslog pipeline
- esp_syslog_udp - udp syslog pipeline

## 2.0.40 (2023-06-27)

The version contains updates to support using variables for the elastic nodes in
the Kibana.yml file

### Changed

- installKibana.sh - Correct syntax in case statement
- upgrade_nodes.sh - Update Kibana override file on upgrade

## 2.0.39 (2023-06-26)

This version contains various updates for minour issues found during the 8.6.2
upgrade testing before CTE. It also contains additions that are coming in the Q2
release but may be needed beforehand.

- New ingestion method for DLP events from HBSS

### Changed

- activate_acas.sh - Update cron file permissions and elastic privileges
- activate_serena.sh - Update cron file permissions
- installElasticDataCollector.sh - Added install ownership and permissions for
  DLP
- installElasticNode.sh - update case code for numNode options
- installKibana.sh - Remove depricated --allow-root option
- load_roles.sh - fix misplaced parentheses in regex
- estc_hbss-epo-mappings - New mappings for DLP events
- get_pipelines.sh - Updated to remove /r
- update_logstash_pipelines.sh - Added esp_hbss_dlp pipeline
- ElasticConnection.py - Remove carriage returns from file
- Querier.py - Remove carriage returns from file
- StaleCleanup.py - Remove carriage returns from file
- configurator.py - Remove carriage returns from file
- version.py - Remove carriage returns from file
- constants.py - Use seconds for data collector up time
- acas.cron - Remove carriage returns from file
- stale_cleanup.cron - Remove carriage returns from file

### New

- scripts/shell/hbssdlp.bash - Driver script for getting HBSS DLP events
- install/pipelines/esp_hbss_dlp - Pipeline that uses exec input plugin to call
  hbssdlp.bash
- install/activate_hbssdlp.sh - Create dat file that contains hostname, port,
  username, and assword for hbsslp.bash script

## 2.0.38 (2023-05-25)

This version contains updates from minor issues found during the MTE upgrade and
also changes required for the installation on REL systems.

### Changed

- esp_winlogbeat - Updates to not send to ingest routing if data coming from
  older version
- activate_acas.sh - Added ability to change ACAS server name during install
- installElasticNode.sh - Updated to work for REL installation
- installKibana.sh - Updated to work for REL installation
- installLogstash.sh - Updated to work for REL installation
- installMetricbeatkeystore.sh - Updated to allow running on install
- installWatchers.sh - Fixed checks for HTTP return codes
- load_ILM_Policy.sh - Updated to work for all cluster sizes
- load_objects.sh - Updated to create spaces on install only
- load_templates.sh - Added current-healthdata and updated maas names
- make_elastic_csrs.sh - Updated for use on 6 node cluster
- reindex_renamed_indices.sh - Updated to use SUDO_USER
- updateLicense.sh - Added password verification
- Default-Space-Objects.ndjson - Updated drill down for data collector to use
  title

### Removed

- load_pipelines.sh - Script no longer used

## 2.0.37 (2023-05-04)

This verison adjusts the auditd and iptables ingest pipelines. It also changes a
line in ACAS.py so that it compiles. This version also changes esp_linux_syslog
to correctly send message field to auditd and iptables ingest pipelines. It also
adds a fix to StaleCleanup.py to correctly use time format and now to filter by
site. An update to load_objects.sh and the final ndjson file for objects in the
Default space is also included.

### Changed

- filebeat-8.6.2-auditd-log-pipeline - Handle multiple spaces within the message
  field (Added \s+), use a script to remove geoip database unavaiable in tags.
- filebeat-8.6.2-iptables-log-pipeline - Add ignore failure to rename message to
  event.original, use a script to remove geoip database unavaiable in tags.
- esp_linux_syslog - Added section that copies node correctly into it's own
  field without dissecting. Added a section to correctly send message for
  iptables.
- ACAS.py - Removed setName function as the class isn't a thread anymore.
- StaleCleanup.py - Added time format check, made it filter by site.
- load_objects.sh - Updated to load multiple ndjsons correctly

### New

- Default-Space-Objects.ndjson - Holds all objects for release

## 2.0.36 (2023-04-28)

This version updates the ElasticInfo class, Vsphere.py, and Querier.py to be
able to set the status of the Elastic Data Collector to degraded if it is unable
to query Vsphere or Elasticsearch.

### Changed

- ElasticInfo.py - "app.HealthSymptoms" field added to Data Collector Health
  Doc, methods added to handle symptoms, method that updates Data Collector
  status updated to become degraded if any symptoms are present.
- Querier.py - added capability to add a symptom to ElasticInfo if unable to
  query Elasticsearch.
- Vsphere.py - added capability to add a symptom to ElasticInfo if unable to
  query Vsphere.
- estc_healthdata-mappings - updated with most recent mappings
- version.py - Elastic Data Collector version updated
- Document.py - adds Data Collector symptoms to the Symptoms class
- RequestHandler.py - updates API calls to use updated ElasticInfo methods

## 2.0.35 (2023-05-02)

This version fixes the ART artifacts to work in 8.6.2.

### Changed

- dcgs-gxpxplorer.ndjson - Correct filters used on visuals and dashboards.
- dcgs-socetgxp.ndjson - Correct filters used on visuals and dashboards.
- esti_maas_logs - Change default search fields to '\*'
- reindex_renamed_indices.sh - Add event.original in reindex scripts; describe
  script formatting.

## 2.0.34 (2023-04-25)

This version incorporates the SOCET, Xplorer, MAAS artifacts and updates install
scripts.

### Added

- dcgs-socet.ndjson - Dashboards/visuals/searches for SOCET.
- estc_socet-mappings - SOCET component template.
- esti_socet - SOCET index template.
- socet_gxp.yml - SCCM Filebeat config for SOCET
- dcgs-xplorer.ndjson - Dashboards/visuals/searches for Xplorer.
- estc_xplorer-mappings - Xplorer component template.
- esti_xplorer - Xplorer index template.
- gxp_xplorer.yml - SCCM Filebeat config for Xplorer
- dcgs-maas.ndjson - Dashboards/visuals/searches for MAAS.
- estc_maas-mappings - MAAS component template.
- esti_maas - MAAS index template.
- gxp_maas.yml - SCCM Filebeat config for MAAS
- test_data/ - top-level directory for any test data for verifying changes,
  subdirectories for test data from SOCET, Xplorer, MAAS, & SOAESB

### Changed

- bootstrap_indexes.sh - Add SOCET, Xplorer, MAAS indexes to 'indexes' list.
- load_objects.sh - Add SOCET, Xplorer, MAAS ndjsons to list.
- reindex_renamed_indices - replace content with ARTs indexes, remove sudo need,
  add script option to reindex command
- esp_filebeat - Add SOCET, Xplorer, MAAS filter sections
- inputs.txt - Add SOCET, Xplorer, MAAS configurations

## 2.0.33 (2023-04-11)

This version has a few hotfixes for ACAS and other scripts so that it is ready
for 8.6.2 release.

### Added

- estc_acas-mappings - Component template mappings for ACAS
- esti_acas - index template for ACAS

### Changed

- activate_acas.sh - Added echo statements for readability and bootstrapping of
  index
- ACAS.py - Fixed a possible infinite loop
- load_templates.sh - Added ACAS component and index templates
- esp_sccm_database - Changed service account to have a dynamic site
- update_logstash_pipelines.sh - removed the check on esp_sql_server_stats to
  rename
- upgrade_logstash.sh - Added section to create realmDom
- install_beats_windows.ps1 - Added versioning to script
- AuditCheck.py - Fixed typo at line 241
- CiscoSwitch.py - Fixed typo at line 490

## 2.0.32 (2023-04-10)

This change fixed the pull_ingest_pipelines script, find command and some clean
up in the upgrade_node script, some logic errors in the upgrade_logstash script,
added the singleworker to the update_logstash_pipelines script and baselines the
filebeat and winlogbeat 8.6.2 ingest pipelines.

### Changed

- pull_ingest_pipelines.sh - changed the --modules flag to --enable-all-filesets
- update_logstash_pipelines.sh - added singleworker
- upgrade_logstash - updated logic and password check to fix errors
- upgrade_node - updated the find command, minor revisions for version 8.6.2
- baselines filebeat and winlogbeat 8.6.2 ingest pipelines

## 2.0.31 (2023-04-07)

This change adds all index templates and component templates for filebeat,
heartbeat, metricbeat, and winlogbeat version 8.6.2.

### New

- estc_filebeat-8.6.2-mappings - filebeat component template mappings for 8.6.2
- estc_heartbeat-8.6.2-mappings -heartbeat component template mappings for 8.6.2
- estc_hbss-epo-mappings - hbss-epo component template mappings updated to
  relfect correct total field limit size
- estc_metricbeat-8.6.2-mappings - metricbeat component template mappings for
  8.6.2
- estc_winlogbeat-8.6.2-mappings - winlogbeat component template mappings for
  8.6.2
- esti_filebeat-8.6.2 - filebeat index template for 8.6.2
- esti_heartbeat-8.6.2 - heartbeat index template for 8.6.2
- esti_winlogbeat-8.6.2 - winlogbeat index template for 8.6.2

## 2.0.30 (2023-04-04)

This change updates install_beats_windows.ps1 so that a filebeat config file can
have -SW on the end for a singleworker configuration.

### Changed

- install_beats_windows.ps1 - Added check so that filebeat config yaml file can
  have -SW to indicate a singleworker.
- inputs.txt - Added section describing the singleworker pipeline

### Added

- inputsByService.txt - input file to configure services with
  install_beats_windows.ps1

## 2.0.29 (2023-03-31)

This change adds logic to activate_acas.sh to allow the installer to check if
the api keys work or not, It also changes the usage of 2 seperate sets of keys
to one, and it now encrypts the api keys. This change also updates ACAS.py so
that the installer can run a test function for the api keys and can decrypt the
keys.

### Changed

- activate_acas.sh - Logic to tell installer if keys work, writes 1 set of keys
  now.
- ACAS.py - Added functionality to decrypt API keys, added a test function for
  the installer.

## 2.0.28 (2023-03-29)

This change adds the No_Audits symptom for hosts to the Elastic Data Collector.

### New

- AuditCheck.py - adds AuditCheck class to add No_Audit as a symptom if the host
  is not in the winlogbeat or syslog indexes

### Changed

- estc_healthdata-mappings - adds audits to mappings
- Hosts.py - adds audit symptom tp document
- constants.py - adds AUDIT section(AUDITS_TIME and AUDIT_QUERY_TIME)
- Document.py - adds NO_AUDITS and NONE_AUDIT variables
- elasticDataCollector.py - adds AuditCheck

## 2.0.27 (2023-03-29)

This version adds an additional instructions to rerun the update logstash script
if errors occur during the upgrade with the heartbeat.yml file is missing. It
also adds the JVM.options function to update the size of the JVM based on the
machine's memory. This version also removed the 7.17 curl commands to rollover
switch indexes. This version also creates a password check for the user
performing the update.

### Changed

- upgrade_logstash.sh - added jvm.options function to update JVM size. Added
  instructions to rerun update logstash script if heartbeat.yml is missing.
- bootstrap_indexes.sh - removed curl commands to rollover switch indexes to
  prepare for the new Temp Field.
- upgrade_logstash.sh - added password check

## 2.0.26 (2023-03-29)

This version incorporates the SOAESB artifacts and updates scripts.

### Added

- ART_INTEGRATION.md - Instructions for adding an integration from the
  oadcgs-es-elastic-arts repo.
- devUtils/insertSectionIntoPipeline.sh - script for inserting a filter section
  into a logstash pipeline.
- dcgs-soaesb.ndjson - Dashboards/visuals/searches for SOAESB.
- estc_soaesb-mappings - SOAESB component template.
- esti_soaesb - SOAESB index template.

### Changed

- bootstrap_indexes.sh - Add SOAESB index to 'indexes' list.
- load_objects.sh - Change to use list of ndjson files; add SOAESB ndjson to
  list.
- esp_filebeat-singleworker - Fix escape codes; add SOAESB filter section

## 2.0.25 (2023-03-29)

This version fixes an issue where the process spawned to do SNMP requests does
not exit properly causing a thread to hang.

### Changed

- Device.py - timeout on join and terminate process if hung

## 2.0.24 (2023-03-28)

This version updates install_beats_windows.ps1 to configure filebeat on windows
based on presence of a service.

### Changed

- install_beats_windows.ps1 - Added code to get_filebeat_inputs function that
  allows for the function of configuring filebeat based on the presence of a
  service.

## 2.0.23 (2023-03-27)

This version configures the ingest of REnDER ART data. It is completed by adding
REnDER to the esp_filebeat-singleworker pipeline, bootstrap_indexes.sh, and
load_templates.sh. It also adds in configurations for estc_render-mappings,
esti_render and the filebeat.yml.

### New

- estc_render-mappings - REnDER component template mappings
- esti_render - REnDER index template
- render.yml - adds in the filebeat inputs for a multiline, path, and tags for
  'render'

### Changed

- bootstrap_indexes.sh - adds in the dcgs-filebeat-geo-ha-render-logs to the
  indexes
- esp_filebeat-singleworker - adds in the REnDER filter section within the
  singleworker pipeline
- load_templates.sh - adds in esti-render in the index_template section. Also
  adds in estc_render-mappings to the comp_template section.

## 2.0.22 (2023-03-21)

This version adds a version number to the Elastic Data Collector, which is to be
updated any time changes are made to the data collector and starts at 2.1.0.
ElasticInfo.py has been updated to contain this new version field, as well as
add methods to return it and write it to ElasticSearch. This version also
updates RequestHandler.py to return the data collector version in API calls and
updates the estc_healthdata-mappings template to accomodate the new field.

### Changed

- ElasticInfo.py - adds the new data collector version field, and supplies a
  method for returning the version and writing it to Elastic
- RequestHandler.py - adds a new 'version' field to all API responses
- elasticDataCollector.py - removes commented out ACAS code, which has been
  converted to running as a cron job
- estc_healthdata-mappings - adds new 'version' field to the mappings

### Added

- version.py - this contains the version number for the Elastic Data Collector

## 2.0.21 (2023-03-20)

This version adds functionality to the winlogbeat pipeline to parse
impersonation data.

### Changed

- esp_winlogbeat - Code added to parse Impersonation fields based off of an
  in-line dictionary

## Added

- estc_winlogbeat-8.6.1-mappings - New fields exist due to changes in the
  winlogbeat pipeline. Also adding the new 8.6 mapping to baseline.

## 2.0.20 (2023-03-17)

This version updates esp_metricbeat to support data streams.

### Changed

- esp_metricbeat - remove indexing by id and add action => create to index a
  document in a data stream

## 2.0.19 (2023-03-16)

This version adds a new script for comparing two ndjson files. The script is
used by the devlopment team to ensure the contents of the delivered ndjson files
are correct.

### Added

- compareNdJson.py - New script that prints contents of ndjson file or compares
  two ndjson files

### Changed

- mibdump.py-help.txt - Updated name to remove space in filename
- esp_filebeat-singleworker - Fix escape codes; add SOAESB filter section

## 2.0.18 (2023-03-01)

This version renames insertIntoFilebeatPipeline to insertIntoPipeline and
modifies it to take an optional pipeline name to update, and modifies
InstallLogstash to save the domain name to sysconfig/logstash, so SOAESB can
format the URL if it is not provided.

### Changed

- insertIntoPipeline.sh - rename from insertIntoFilebeatPipeline.sh and use
  LOGSTASH_PIPELINE if it exists, otherwise default to esp_filebeat.
- InstallLogstash.sh - save dnsDom to DOMAINNAME in sysconfig/logstash.

## 2.0.17 (2023-02-28)

This version fixes an issue with the vSphere thread printing "Unable to query
data from vSphere API, will try again in 60 seconds" at several sites on High
and Low.

### Changed

- Vsphere.py - a try/except block was added to allow Vsphere.py to check if it
  is connected to Vsphere again.

## 2.0.16 (2023-02-28)

This version adds a new function, RemoveScheduledTasks, to the
install_beats_windows.ps1 script to remove scheduled tasks that contain "beats"
in the name to clean up unwanted scheduled tasks.

### Changed

- install_beats_windows.ps1 - adds a new function, RemoveScheduledTasks, to the
  install_beats_windows.ps1 script to remove scheduled tasks that contain
  "beats" in the name

## 2.0.15 (2023-02-28)

This version adds the new winlogbeat ingest pipelines that came with the upgrade
to Elastic version 8.6.1. It also makes updates to the winlogbeat.yml file,
removing the processors as they are no longer needed. It also updates
pull_ingest_pipelines.sh and update_ingest_pipelines.sh to pull and update the
new winlogbeat pipelines. It also adds a new script,
export_winlogbeat_ingest_pipelines.ps1 script that loads the new pipelines on a
windows box. Finally, this version updates esp_winlogbeat to write output to the
new routing pipeline.

### Added

- export_winlogbeat_ingest_pipelines.ps1 - loads new winlogbeat pipelines into
  Elastic
- winlogbeat-8.6.1-powershell
- winlogbeat-8.6.1-powershell_operational
- winlogbeat-8.6.1-routing
- winlogbeat-8.6.1-security
- winlogbeat-8.6.1-sysmon

### Changed

- pull_ingest_pipelines.sh - adds new winlogbeat pipelines to the list of
  pipelines to be pulled
- esp_winlogbeat - adds new winlogbeat routing pipeline to output
- update_ingest_pipelines.sh - adds new winlogbeat pipelines to the list of
  pipelines to be updated
- ec01.winlogbeat.yml - removes processors from modules

## 2.0.14 (2023-02-28)

This version sets the device component templates to use designated fields as
default search fields to all of the device indexes.

### Changed

- estc_dellidrac-mappings - added log.file.path, metadata.Desc,
  metadata.DocSubtype, metadata.DocType as default search fields
- estc_ciscoswitch-mappings - added log.file.path, metadata.Desc,
  metadata.DocSubtype, metadata.DocType as default search fields
- estc_fx2-mappings - added log.file.path, metadata.Desc, metadata.DocSubtype,
  metadata.DocType as default search fields
- estc_datadomain-mappings - added log.file.path, metadata.Desc,
  metadata.DocSubtype, metadata.DocType as default search fields
- estc_isilon-mappings - added log.file.path, metadata.Desc,
  metadata.DocSubtype, metadata.DocType as default search fields
- estc_xtremio-mappings - added log.file.path, metadata.Desc,
  metadata.DocSubtype, metadata.DocType, event.description as default search
  fields

## 2.0.13 (2023-02-23)

This version modifies the logic to the Fx2 script to look for the drsServerModel
key in addition to the chassis_info_copy key when deleting "N/A" values.

### Changed

- Fx2.py - Changed logic in line 322 to look for the drsServerModel when
  removing empty values

## 2.0.12 (2023-02-27)

This version adds the ACAS.py Functionality to be run as a CRON job. It also
cleans up some functionality to satisfy M&S Team's requirements. Those being
security as it now moves to using just 1 Account. System Status functionality
has been put on hold due to this.

### Changed

ACAS.py - Can now be run as a CRON job. Changed to satisfy security requirements
from M&S Team. activate_acas.sh - Added copy command to put acas cron in
cron.daily folder activate_serena.sh - Added copy command to put serena cron in
cron.daily folder

## 2.0.11 (2023-02-24)

This verison adds a check before adding a role to the querier user so that roles
don't get overwritten. It allows for dynamic creation of roles and rolenames.
This verison also adds the stale-delete role to load_roles.sh

### Changed

activate_acas.sh - Adds check so that rolenames don't get overwritten.
activate_serena.sh - Adds check so that rolenames don't get overwritten.
load_roles.sh - Adds stale-delete role to querier.
installElasticDataCollector.sh - Assigns stale-delete role to querier.

## 2.0.10 (2023-02-18)

This version sets the dcgs_default component template to use event.original as
the default field. It also changes non-device component templates to include
default fields if event.original does not exist. All index templates are
modified to use the dcgs_defaults component template first so any custom default
fields will overwrite the standard event.original.

### Changed

- upgrade_logstash.sh - Changed the order of the dynamic component templates
  that are created to load dcgs_defaults first
- esti\_\* - Changed the order of the component templates to load dcgs_defaults
  first
- estc\_\* - Included default and max fields for non-device indices if
  event.original does not exist

## 2.0.9 (2023-02-06)

This version adds the StaleCleanup.py class that will look through the
dcgs-current-healthdata index and delete objects that have been stale for longer
than 7 days. It also adds constants to configure these times.

### Added

StaleCleanup.py - Class that cleans up the current-healthdata index.

### Changed

constants.py - added variables to configure StaleCleanup.py

## 2.0.8 (2023-02-07)

This version adds the new Elastic Data Collector API functionality. It adds
RequestHandler.py, a class that handles API requests sent to it and returns
responses to the requester. It also adds DataCollectorListener.py, a thread that
runs in the Data Collector and instantiates the RequestHandler. This version all
adds ElasticInfo.py, a class that holds information on the apps, hosts, groups,
and threads running in the data collector, as well as several new methods. It
also brings changes to elasticDataCollector.py, changing it to utilize the
ElasticInfo class as the primary method of storage. Finally, this version adds
Data Collectors to list of things the esw_current-healthdata-stale-state watcher
changes to 'stale' when needed, as well as bringing a bug fix to
installWatchers.sh.

### Changed

- elasticDataCollector.py - The Data Collector now uses the ElasticInfo class
  for most operations and also instantiates and runs a new thread,
  DataCollectorListener.
- installWatcher.py - Fixes a bug in which watchers that already exist in
  Elastic could not be updated.
- esw_current-healthdata-stale-state - Adds 'datacollector' to the types of
  Document SubTypes that can be made 'stale' by the watcher.

### Added

- ElasticInfo.py - This class holds information on the apps, hosts, groups, and
  threads running in the data collector, as well as several new methods.
- RequestHandler.py - This class handles API requests sent to it and returns
  responses to the requester.
- DataCollectorListener - This class is a thread that runs in the Data Collector
  and instantiates the RequestHandler.

## 2.0.7 (2023-02-06)

The health class in DellIdrac.py and FX2.py has been updated in this version. In
both files, functionality is added to check if the system Health class is OK,
and then the symptom "None" is added. If the system fails, it adds a symptom for
the specific health class.

### Changed

- DellIdrac.py - Added when the health class is degraded, the user is identified
  with the correct symptom.

- FX2.py - Added when the health class is degraded, the user is identified with
  the correct symptom.

- CiscoSwitch.py - Added when the health class is degraded for the Fan, the user
  is identified with the correct symptom.

- Document.py - Updated the class Symptom section to incorporate the updated
  symptoms.

## 2.0.6 (2023-01-23)

This version adds an update to the CiscoSwitch class of the Elastic Data
Collector. The change ensures that the physical entity dictonary is created to
allow correct mappings before allowing other queries to switches.

### Changed

CiscoSwitch.py - Ensure get enitiy list is sucessful before allowing other
queries.

## 2.0.5.1 (2023-01-20)

This feature includes the new pipeline that will be used for single worker
configurations which utilize port 5043.

### Added

- esp_filebeat-singleworker - Mirror pipeline to the esp_filebeat pipeline but
  now uses one worker and port 5043

## 2.0.5 (2023-01-11)

This feature modifies the install_beats_windows script to check for the SW
(single worker) tail to yml files. If so, filebeat will run on port 5043.
Inputs.txt can append :SW to designate single worker required or the filebeat
configuration provided can be specified with a "-SW" (ex: ha01.filebeat-SW.yml)

### Changed

- install_beats_windows.ps1 - Added logic to determine if single worker has been
  identified in the yml config. If so, will run on port 5043

## 2.0.4 (2023-01-11)

This version updates appmonitor_win.js script to reduce the number of processes
monitored

### Changed

- appmonitor_win.js - changed to drop windows events when an event happens
  within the system32 directory and we don't already monitor it

## 2.0.3 (2023-01-10)

This version adds the script activate_acas.sh for deletion of acas data.

### Changed

- activate_acas.sh - Added role to acas user to be able to delete data from acas
  index

## 2.0.2 (2022-12-1)

This version updates the Elastic Data Collector to have improved monitoring and
logging. It adds code to elasticDataCollector.py that gathers information on
which Data Collector threads are running, how many threads are running, how many
Data Collector threads are not running (dead), and how many threads are dead. It
marks the status of the Data Collector as "degraded" if a thread is dead. This
version also updates Document.py with the new "datacollector" document subtype,
and provides updates to estc_healthdata-mappings to handle the new "threads"
fields.

### Changed

- elasticDataCollector.py - adds code that collects data about the status of
  Data Collector threads and provides logic for marking the Data Collector
  status as "Ok" or "Degraded"
- Document.py - adds new "datacollector" DocSubtype
- estc_healthdata-mappings - adds mappings for the new "threads" field being
  sent to Elastic

## 2.0.1 (2022-11-21)

This version updates esp_filebeat-logstash and esp_metricbeat to ingest data
into dcgs-current-healthdata index. It also adds the esti_current-healthdata
index template.

### Changed

- esp_filebeat-logstash - allows ingest to output into dcgs-current-healthdata
  non-time series index
- esp_metricbeat - allows ingest to output into dcgs-current-healthdata non-time
  series index

### Added

- esti_current-healthdata - Index template that modifies how current-healthdata
  index looks

## 2.0.0 (2022-11-14)

This version adds the esw_current-healthdata-stale-state Watcher and
installWatchers.sh. esw_current-healthdata-stale-state is the Watcher that
changes data in current-state-healthdata and changes it to stale when a certain
amount of time has passed. installWatchers.sh uses an array of predefined
watchers and pulls them from the repo servers and pushes them into elastic.

### Added

- esw_current-healthdata-stale-state - Watcher to check for Stale data in
  current-state-healthdata
- installWatchers.sh - Install script for array of watchers

## 1.8.65 (2023-04-19)

This version fixes an issue with the script used to correct the name of the
index that stores sql server statistics.

### Changed

- update_logstash_pipelines.sh - fix logic that updates index name for sql
  server statistics.

## 1.8.64 (2023-03-28)

This version fixes an issue where the process spawned to do SNMP requests does
not exit properly causing a thread to hang.

Changed

Device.py - timeout on join and terminate process if hung

## 1.8.63 (2023-03-13)

This version adds addtional updates for issues found during testing on MTE

### Changed

- savedObjects_7.17.ndjson - Removed duplicate index templates. Removed site=u00
  filters on some dashboards
- load_role_mapping.sh - Updated to handle line feeds in data retuned from ldap
  queries
- load_templates.sh - Added missing templates; estc_dcgs_app_defaults and
  estc_loginisight-agent-mappings
- make_logstash_csr.sh - Added new generic alternative name "logstash"
- esp_metricbeat - Removed tabs (there should be no tabs in the file)
- esp_sccm_database - Made jdbc_connection_string generic to allow pipeline
  reloading on any system
- update_kibana_settings.sh - Updated to get version from kibana and also give
  message if run on wrong machine
- upgrade_logstash.sh - Updated to add new DOMAINNAME variable in
  /etc/sysconfig/logstash
- upgrade_node.sh - Updated to add TimeoutStartSec=180 to Elasticsearch override
  file

## 1.8.62 (2023-02-09)

This version adds updates for issues found during initial testing on MTE

### Changed

- upgrade_node.sh - Removed duplicate lines from bad merge. Modified order of
  calls to ensure configs are updated before upgrade. Added missing "-k" to some
  curl requests.
- removeCurator.sh - Modifed to determine user with $SUDO_USER
- make_logstash_csr.sh - Added generic "logstash" alias

## 1.8.61 (2023-02-09)

This version changes the visuals for 7.17 to have the correct size values for
many of the dashboards

### Changed

- savedObjects_7.17.ndjson - Changed certain visuals to have the correct sizing
  for different dashboards

## 1.8.60 (2022-12-16)

This version contains the final updates preparing for the 7.17 RFC

### Changed

- filebeat-7.17.6-auditd-log-pipeline - Removed geoip processors
- esp_linux_syslog - updaqted json parsing to use "Log" target

### Added

- savedObjects_7.17.ndjson - Visual, dashboard, index patterns and saved
  searches for 7.17
- esp_filebeat-syslog - pipleine OBE and no longer needed

### Removed

- savedObjects_7.12.ndjson - File replaced by savedObjects_7.17.ndjson

## 1.8.59 (2022-12-15)

The Configurator, CiscoSwitch, and several other files have been updated to
account for the Nexus 7k Switch CPU and Inlet temperatures. This update also
includes fan symptoms and average, minor, and major temperature deviations which
also passes health symptoms.

### Changed

- bootstrap_indexes - Dcgs-device switch 7k-iaas-ent is added to the indexes
  section. The dcgs-audits syslog-iaas-ent is also removed from the indexes
  section. Finally, to prepare for new fields, adds a rollover function for the
  existing switch indexes.
- CiscoSwitch.py - Adds a variable to determine the fan's Health Symptom. Also
  adds an alert on possible over temperature on the catalyst, Nexus 5k, and
  Nexus 7k switches.
- configurator.py – The configurator code has been majorly updated with a more
  efficient structure. The Nexus 7k switch has been added to the configurator.
  This modification also alters the edit section by including a drop down in the
  new "Device Name" section for the edit window. This allows the user to change
  the switch device type to one of three options: Catalyst, Nexus 5k, or Nexus
  7k.
- constants.py - Adds average, minor, and major temperature constants to be
  measured on Catalyst, Nexus 5k, and Nexus 7k Inlets and CPUs.
- Device.py - Adds in the Nexus 7k as a class Device Type.
- Document.py – Major and minor temperature are now included as symptoms for the
  CPU and Inlets. The Fan degraded symptom has also been included. The Data
  collector was added to the docsubtype. Finally, the method used to set a
  metadata for the switch sensors.
- elasticDatacollector.py - Adds in the Nexus 7k as a device type.
- esp_filebeat-logstash - Adds in the Nexus 7k.
- estc_ciscoswitch-mappings - Adds temperature mappings for the inlet and CPU
  temperatures as floats.
- esti_nexus7k - Creates the Nexus 7k template.
- testaccess.py – Adds in the Nexus 7k as a device type.
- load_templates.sh - Adds the esti_nexus7k to the index_templates section.

## 1.8.58 (2022-12-06)

This version has various updates made in prepartion for the 7.17 RFC.

### Changed

- update_logstash_pipelines.sh - Added metricbeat pipeline to be updated
- load_ILM_Policy.sh - Script renamed for consistency, fixed parameters and
  updated to always load ILM Policy
- load_auditsettings.sh - Updated to allow running on both upgrades and fresh
  install
- installLogstash.sh - Updated to use new keystores directory
- load_role_mapping.sh - Updated to work for both upgrades and fresh install
- load_roles.sh - Updated to work for both upgrades and fresh install
- esp_metricbeat - Add test for nil on mem_tot_bytes
- upgrade_logstash.sh - Update prompt for clarity on isec site
- installElasticDataCollector.sh - Update prompt for clarity on isec site
- esp_puppet_database - Updated to make pipeline generic
- load_SLM_Policy.sh - Added dcgs-audits_syslog for archiving and fixed to
  always update policy
- estc_hbss-epo-mappings - Change event.original to text field
- esp_filebeat - changed the pipeline.batch.size to 800 and the pipeline.workers
  to 3
- esp_linux_syslog - changed the pipeline.batch.size to 1000 and the
  pipeline.workers to 3
- esp_winlogbeat - changed the pipeline.batch.size to 2250 and the
  pipeline.workers to 4
- esp_loginsight - changed the pipeline.batch.size to 2750 and the
  pipeline.workers to 8

### Added

- RemoveCurator.sh - New script to remove previously installed Curator
- VerifyArchiveDir.sh - New script to ensure elastic archive directory exists on
  Isilon
- load_7.17_objects.sh - New script to load 7.17 objects

### Removed

- update_auditsettings.sh - combined with load_auditsettings.sh
- esti_syslog - Removed unused index template
- load_7.12_objects.sh - Removed/replaced by load_7.17_objects.sh

## 1.8.57 (2022-12-06)

This version fixes the ablity for the install_beats_windows.ps1 script to detect
if a program is installed on a windows computer.

### Changed

- install_beats_windows.ps1 - The technique used to get the list of installed
  programs has been modifed to use the "reg query" call that allows the
  specification of which area of the registry to look in (/reg:32 or /reg:64).
  The script now looks for both 32bit and 64bit installed software.

## 1.8.56 (2022-12-06)

This version configures the ingest of Guardian ART data through the existing
syslog configurations. It also adjusts the upgrade_logstash script to
dynamically create syslog index templates including the dcgs_app_defaults
component template.

### Changed

- esp_linux_syslog - Tags Guardian data based on process name. Adds data for the
  new dcgs_app_defaults fields of Guardian data. Points etcd json parsing to the
  "Log." fields.

- upgrade_logstash.sh - Dynamically includes the new dcgs_app_defaults with the
  syslog index template

- estc_syslog-mappings - New fields added from new json etcd parsing.

## 1.8.55 (2022-12-06)

This version fixes a bug in the Watcher class of the ElasticDataCollector. The
update protects against trying to call the seek method if the hosthealth file
has not yet been created by Logstash.

### Changed

- Watcher.py - Added check to see if filehandle is None and increased sleep to
  wait for file creation to 5 seconds.

## 1.8.54 (2022-11-29)

This version updates the serena_activate.sh script to create the serena-delete
security role and assigns that role to the site's querier-xx user.

### Changed

- activate_serena.sh - adds code to create the serena-delete role and assign the
  role to the site's querier user.

## 1.8.53 (2022-11-18)

This version adds a new defaults component template for application data.

### Added

- estc_dcgs_app_defaults - Mappings for common field in application data.

## 1.8.52 (2022-11-07)

This version updates insertIntoFilebeatPipeline.sh to allow it to be called from
another script. There is also a minor update to the estc_syslog-mappings.

### Changed

- insertIntoFilebeatPipeline.sh - added password parameter and check curl
  results
- estc_syslog-mappings - Update took value to long

## 1.8.51 (2022-11-03)

This version adds a dark mode configuration for initial install spaces

### Changed

- update_kibana_settings.sh - Add logic to set dark mode for initial install
  spaces

## 1.8.50 (2022-11-03)

This version changes the log4j2.properties file to roll files every day or every
100MB, and it only keeps 5 of each log file type. It also updates the upgrade
scripts to replace the old log4j2 with the new.

### Changed

- upgrade_node.sh - Removed lines that edited the log4j2 file, replaced with a
  copy from the repo server
- upgrade_logstash.sh - Removed lines that edited the log4j2 file, replaced with
  a copy from the repo server

### Added

- log4j2.properties.logstash - Modified rolling and deleting lines to roll daily
  or 100MB, only keeps 5 files
- log4j2.properties.elasticsearch - Modified rolling and deleting lines to roll
  daily or 100MB, only keeps 5 files

## 1.8.49 (2022-10-17)

This version updates the ElasticDataCollector to keep it from exiting if the
deviceconfig.json file is not present. This allows the ElasticDataCollector to
run if device monitoring has not been configured. Additionally, CiscoSwitch.py
has been updated to keep from printing debug messages

### Changed

- ElasticDataCollector.py - allows the script to continue without the
  deviceconf.json file
- CiscoSwithc.py - removed a print statement

## 1.8.48 (2022-10-27)

This version adds the esti_serena index template and the estc_serena-mappings
component template. It also updates the activate_serena.sh script to bootstrap
the Serena index and updates the load_templates.sh script to load the
esti_serena index template and the estc_serena-mappings component template.

### Changed

- activate_serena.sh - adds the capability to bootstrap Serena index
- load_templates.sh - adds the esti_serena index template and the
  estc_serena-mappings component template to the lists of templates to be
  loaded.

### Added

- esti_serena - the Serena index template
- estc_serena-mappings - the Serena component template

## 1.8.47 (2022-10-17)

This version updates the ElasticDataCollector to allow the ability to create
Host Health Documents correctly for Workstation Unix(wu) hosts.

### Changed

- Querier.py - adds hosttype for Workstation Unix

## 1.8.46 (2022-10-05)

This version adds the initial query to the esp_serena_database pipeline which
queries for all open tickets when the pipeline is started. This query runs once
and the pipeline subsequently queries for only updated tickets. This version
also adds the activate_serena.sh script, which the installer uses to configure
and load the esp_serena_database pipeline.

### Changed

- esp_serena_database - adds initial query for all open tickets

### Added

- activate_serena.sh - configures the database string for esp_serena_database
  and loads the pipeline into Elastic.

## 1.8.45 (2022-09-25)

This version adds a classification security banner to each of the spaces

### Changed

- update_kibana_settings.sh - Add logic to set classification security banner

## 1.8.44 (2022-09-30)

This version dynamically updates the sccm database name used in the
esp_sccm_database pipeline based on the classification of the environment.

### Changed

- update_logstash_pipelines.sh - Adds logic to update database name based on
  classification of environment

## 1.8.43 (2022-09-28)

This version changes where data_content is stored on nodes. Data_content will
now be stored on ML and data_hot nodes

### Changed

- upgrade_node.sh - Add data_content to ML and data_hot nodes and remove
  data_content and remove data_content from data_warm nodes

## 1.8.42 (2022-09-21)

This version adds logic to set path based on number of nodes and add
tier_preference data_hot and fix linting errors

### Changed

- upgrade_node.sh - Add logic to set path based on number of nodes
- estc_dcgs_defaults - Add \_tier_preference : data_hot
- Querier.py - Fix linting errors
- estc_vsphere-mappings - Update mappings

## 1.8.41 (2022-09-23)

This version adds the SerenaCleanup.py class. This class runs once a day and
deletes inactive tickets from the dcgs-db_serena-iaas-ent index. This version
also adds serena_cleanup.cron, a cron job that calls SerenaCleanup.py once per
day to cleanup inactive serena tickets.

### Added

- SerenaCleanup.py - Python class that deletes inactive Serena tickets
- serena_cleanup.cron - Cron job that calls SerenaCleanup.py, placed in
  cron.daily directory

## 1.8.40 (2022-09-15)

This version verifies that all templates and pipelines load into Elastic with no
errors. It also removes deprecated pipelines and templates from baselines and
bootstraps.

### Removed

- esp_arcsight_udp
- esp_auditbeat

## Changed

- load_pipelines.sh - Removed esp_idm_database, esp_arcsight_udp, esp_auditbeat
- update_logstash_pipelines.sh - Removed esp_idm_database, esp_arcsight_udp,
  esp_filebeat-syslog
- esp_eracent_database - Corrected spelling of dcgs
- esp_filebeat - Added line break "\" as needed
- esp_heartbeat - Added line break "\" as needed
- esp_sccm_database - Corrected spelling of dcgs
- esp_serena_database - Corrected spelling of dcgs
- esp_sqlServer_stats - Corrected spelling of dcgs

## 1.8.39 (2022-09-15)

This version adds the ACAS modules and minor updates to ACAS.py and
load_SLM_Policy.sh.

### Changed

- installElasticDataCollecor - Added modules required for ACAS.py to run
- ACAS.py - Added line to ensure API are able to pull correctly. Also minor
  formatting updates
- load_SLM_Policy.sh - Minor update to database to ensure indexes are snap
  shotted
- activate_acas.sh - Add /dev/tty to input requests to work with curl

## 1.8.38 (2022-09-09)

This version adds the ElasticConnection class using the Singleton design
pattern. This class connects to Elastic using the Python module for 1 method in
ACAS.py and 1 method in Querier.py. The version also adds the deletion of ACAS
data before each new query.

### Changed

- Querier.py - Added ElasticConnection Singleton class, changes how Querier
  establishes Elastic Connection
- ACAS.py - Added ElasticConnection Singleton class, adds ACAS functionality to
  connect to Elastic. Delete old data before each new query.

### Added

- ElasticConnection.py - Thread-safe singleton class that allows other modules
  to connect to Elastic using the Python module.

## 1.8.37 (2022-09-09)

This version ensures the indexes and templates are current and validated for the
Quarter 3 release.

### Changed

- esti_hbss-epo - set priority to "201"
- esti_idm - Updated the "estc_idm-mappings" in the composed of section.
- esti_iptables - Updated the file name from to esti_dcgs-iptables to current
  title.
- esti_iptables - Updated the esti_dcgs-iptables rollover_alias to reflect:
  "dcgs-iptables-iaas-ent".
- esti_winlogbeat-7.17.6 - Fixed formatting
- bootstrap_indexes.sh - Removed "arcsight-udp" from index array section.
- bootstrap_indexes.sh - Removed "dcgs-syslog_iaas-ent" from index array
  section.
- bootstrap_indexes.sh - Updated the checking aliases echo for readability.
- load_templates.sh - Removed outdated indexes and component templates from
  index array section.
- README.txt - Removed templates in this update from the README.txt.
- reindex_renamed_indices.sh - Added the puppet index for re-indexing.

### Removed

- estc_arcsight-udp-mappings
- estc_linux-syslog-mappings
- estc_loginsight-mappings
- esti_arcsight-udp
- esti_dcgs-syslog
- esti_linux-syslog
- esti_loginsight

## 1.8.36 (2022-09-09)

This version modifies the Serena pipeline data to be non-timeseries. Logstash
will now only query Serena tickets that have been updated and store only the
most recent version of the ticket. This version also consolidates the Serena
database queries into a single query to avoid querying for the same data
multiple times.

### Changed

- esp_serena_database - Consolidated queries into one query, added tracking
  column to make the data non-timeseries, and added a document_id field to
  ensure the id of each document is the same as the Serena event id.

## 1.8.35 (2022-09-08)

This version updates upgrade_logstash.sh to allow to be run at any time

### Changed

- upgrade_logstash.sh - Changed script to functions also to allow to be run
  multiple times without harm

## 1.8.34 (2022-09-06)

This version adds the -f flag to force an upgrade and small bugfixes to
upgrade_node.sh. Documented in upgrade.py.

### Changed

- upgrade_node.sh - bugfixes and add force flag
- upgrade.py - add force flag for installs

## 1.8.33 (2022-09-06)

This version adds the 7.17.6 filebeat ingest pipelines and updates the scripts
used to obtain and load them.

### Added

- filebeat-7.17.6-auditd-log-pipeline - Added 7.17.6 ingest pipeline
- filebeat-7.17.6-elasticsearch-audit-pipeline - Added 7.17.6 ingest pipeline
- filebeat-7.17.6-elasticsearch-audit-pipeline-json - Added 7.17.6 ingest
  pipeline
- filebeat-7.17.6-elasticsearch-audit-pipeline-plaintext - Added 7.17.6 ingest
  pipeline
- filebeat-7.17.6-elasticsearch-deprecation-pipeline - Added 7.17.6 ingest
  pipeline
- filebeat-7.17.6-elasticsearch-deprecation-pipeline-json - Added 7.17.6 ingest
  pipeline
- filebeat-7.17.6-elasticsearch-deprecation-pipeline-plaintext - Added 7.17.6
  ingest pipeline
- filebeat-7.17.6-elasticsearch-gc-pipeline - Added 7.17.6 ingest pipeline
- filebeat-7.17.6-elasticsearch-server-pipeline - Added 7.17.6 ingest pipeline
- filebeat-7.17.6-elasticsearch-server-pipeline-json - Added 7.17.6 ingest
  pipeline
- filebeat-7.17.6-elasticsearch-server-pipeline-plaintext - Added 7.17.6 ingest
  pipeline
- filebeat-7.17.6-elasticsearch-slowlog-pipeline - Added 7.17.6 ingest pipeline
- filebeat-7.17.6-elasticsearch-slowlog-pipeline-json - Added 7.17.6 ingest
  pipeline
- filebeat-7.17.6-elasticsearch-slowlog-pipeline-plaintext - Added 7.17.6 ingest
  pipeline
- filebeat-7.17.6-iptables-log-pipeline - Added 7.17.6 ingest pipeline
- filebeat-7.17.6-logstash-log-pipeline - Added 7.17.6 ingest pipeline
- filebeat-7.17.6-logstash-log-pipeline-json - Added 7.17.6 ingest pipeline
- filebeat-7.17.6-logstash-log-pipeline-plaintext - Added 7.17.6 ingest pipeline
- filebeat-7.17.6-logstash-slowlog-pipeline - Added 7.17.6 ingest pipeline
- filebeat-7.17.6-logstash-slowlog-pipeline-json - Added 7.17.6 ingest pipeline
- filebeat-7.17.6-logstash-slowlog-pipeline-plaintext - Added 7.17.6 ingest
  pipeline
- filebeat-7.17.6-system-auth-pipeline - Added 7.17.6 ingest pipeline
- filebeat-7.17.6-system-syslog-pipeline - Added 7.17.6 ingest pipeline
- dcgs_ingest_pipeline_updates.txt - Text file describing any updates made to
  pipeline specific to DCGS
- estc_filebeat-7.17.6-mappings - New component template mapping for beat
  version 7.17.6
- estc_heartbeat-7.17.6-mappings - New component template mapping for beat
  version 7.17.6
- estc_metricbeat-7.17.6-mappings - New component template mapping for beat
  version 7.17.6
- estc_winlogbeat-7.17.6-mappings - New component template mapping for beat
  version 7.17.6
- esti_filebeat-7.17.6 - New index template for beat version 7.17.6
- esti_heartbeat-7.17.6 - New index template for beat version 7.17.6
- esti_winlogbeat-7.17.6 - New index template for beat version 7.17.6

### Changed

- filebeat-7.17.6-auditd-log-pipeline - Updated to allow multiple spaces between
  hostname and type fields
- update_ingest_pipelines.sh - Script updated to be more generic and user
  friendly
- pull_ingest_pipelines.sh - Script updated to be more generic

## 1.8.32 (2022-08-22)

This version updates the elastic code base with the hot fixes from 7.16.3
release

### Changed

- installElasticDataCollector.sh - changes noted in sections 1.5.3 - 1.5.5
- installMetricbeatkeystore.sh - changes noted in sections 1.5.3 - 1.5.5
- upgrade_logstash.sh - changes noted in sections 1.5.3 - 1.5.5
- upgrade_node.sh - changes noted in sections 1.5.3 - 1.5.5
- Device.py - changes noted in sections 1.5.3 - 1.5.5
- Document.py - changes noted in sections 1.5.3 - 1.5.5
- Isilon.py - changes noted in sections 1.5.3 - 1.5.5
- configurator.py - changes noted in sections 1.5.3 - 1.5.5

## 1.8.31 (2022-08-26)

This version adds the activate_acas.sh script that allows the Elastic Installer
to Add API Keys and activate the ACAS collector module. It creates acas.dat in
the /etc/logstash/scripts/data. It also updates how ACAS is Initialized in the
ElasticDataCollector.

### Added

- activate_acas.sh - This script allows the elastic to activate the ACAS Module
  In the ElasticDataCollector. It creates acas.dat in the
  /etc/logstash/scripts/data

### Changed

- elasticDataCollector.py - Changed how ACAS is intialized.
- ACAS.py - Changed how the function parses acas.dat.

## 1.8.30 (2022-08-25)

This version fixes the isIP method in the elasticDataCollector used to determine
if strings are an IP addresses.

### Changed

- Device.py - Fixed issued caused by upgrade to python3; unicode casting
  modified to str.

## 1.8.29 (2022-08-17)

This version updates the upgrade_node.sh script to no longer use sed string to
edit the elasticsearch.yml.

### Changed

- Upgrade_node.sh - Removed kibana.yml editing since it is now handled by
  Puppet. Deletes backup elasticsearch.yml files older than 6 months. It adds
  the createElasticyml function that dynamically creates the elasticsearch.yml.
  Swapped upgradable function to still edit the yml files regardless of version.

## 1.8.28 (2022-08-16)

This version fixes the problem where elastic does not start after a reboot. The
upgrade_node.sh is also modified to see if the machine has the most recent
elasticsearch version. If the machine does not, the script will continue with
the upgrade process.

### Changed

- upgrade_node.sh - added code to check the system for available elasticsearch
  updates upgrade.py - updated to ensure file permissions are correctly set
  after upgrade

## 1.8.27 (2022-08-16)

This version adds the esp_serena_database logstash pipeline. This pipeline
queries the Serena database for incident tickets and segment data, as well as
mission category and priority data.

### Added

- esp_serena_database - Logstash pipeline to retrieve Serena ticket data

## 1.8.26 (2022-08-15)

This version changes the index naming for audit mappings to audits_syslog.
Additionally, audits_syslog is now sitebased. audits_syslog is now bootstrapped
in bootstrap_indexes and loaded in load_templates. esti and estc portions are
updated under templates directory. upgrade_logstash now indentifies
audits_syslog and adds estc_loginsight-mappings to the index template. Also
changed filebeat-7.16_auditd ingest pipeline to fix space error.

### Changed

- upgrade_logstash.sh - added audits_syslog, added logic to add loginsight
  component.
- boostrap_indexes.sh - added audits_syslog to be bootstrapped.
- load_templates.sh - added index and component templates for audits_syslog.
- estc_audits_syslog-mappings - changed name from estc_audit-mappings
- esti_audits_syslog = changed name from esti_audit
- esp_loginsight - changed to be sitebased output
- esp_linux_syslog - changed to be sitebased output
- filebeat-7.16-auditd-log-pipeline - fixed error with whitespace in GROK

## 1.8.25 (2022-08-15)

This version updates esp_filebeat to automate adding new filter sections (e.g.
for ART applications), and provides a script for installing those changes.

### Added

- insertIntoFilebeatPipeline.sh - New script to insert new filter section
  content into esp_filebeat during install.

### Changed

- esp_filebeat - Add tag comment to insert new filter content.

## 1.8.24 (2022-08-10)

This version updates upgrade_logstash.sh to remove upgrade changes for
logstash.yml. Puppet now controls logstash.yml

### Changed

- upgrade_logstash.sh - removed references to logstash.yml

## 1.8.23 (2022-08-05)

Created ACAS connector to collect ACAS vuln, scanner, and system data. This
class would be instantiated in elasticDataCollector if constants.ACAS_ON ==
True. This class uses API keys that are stored in acas.dat in the scripts/data
directory to connect to the ACAS server.

### Added

- ACAS.py - Connection to ACAS
- mibdump.py - Allows for MIBS to be compiled to PySNMP MIBS
- mibdump.py.help.txt - Shows how to use mibdump.py to compile MIBS

### Changed

- elasticDataCollector.py - Added class for ACAS connection
- constants.py - Added ACAS dir, on/off switch, and sleep timer

## 1.8.22 (2022-07-20)

This version completes updates for the migration of the elastic data collector
from python 2.7.5 to Pyton 3.6.

### Changed

- installElasticDataCollector.sh - updates to ensure proper installation
- Device.py - updated test_access method to use PYSnmp and also removed
  references to net-snmp
- upgrade_logstash.sh - Updated to remove changes put in for testing in previous
  version

## 1.8.21 (2022-07-19)

This version updates Logstash and Kibana /var/log/messages to be disabled. These
logs are already written to the individual log files and ingested in
Elasticsearch. Added override lines to upgrade_logstash.sh and upgrade_node.sh
and set "StandardOutput=null." Elasticsearch starts with --quiet parameter which
prevents logs going to journal so no change is necessary for elasticsearch
logging.

### Changed

- upgrade_logstash.sh - Added lines for to add the override and set
  StandardOutput=null in the
  /etc/systemd/system/logstash.service.d/override.conf.
- upgrade_node.sh - Added the createKibanaOverride function and set
  StandardOutput=null in the
  /etc/systemd/system/kibana/kibana.service.d/override.conf.

## 1.8.20 (2022-07-12)

This version updates the install_beats_windows.ps1 script to use the hostname
without site designation for logstash.

### Changed

- install_beats_windows.ps1 - Make logstash designation logstash instead of
  logstash-xxx

## 1.8.19 (2022-07-08)

This version updates the esti_audit template to add an auditbeat-dcgs alias that
points to all dcgs-audit_syslogs-iaas-ent indices.

### Changed

- esti_audit - auditbeat-dcgs alias added to the index template
- esti_db_postgres - fixed issue with template that prevented it from loading
  correctly into elastic

## 1.8.18 (2022-07-06)

This version updates the reindex_renamed_indices script to move the newly
reindexed hot indices to warm. It also checks authentication success. Debug
information was removed from output of script.

### Changed

- reindex_renamed_indices.sh - Authentication check added. Code added to move
  new hot indices to warm. Commented out debug output lines.

## 1.8.17 (2022-06-29)

This version updates the loginsight pipeline to make sure the loginsight data is
being placed into the correct index. It also adds further parsing of sudo ,ssh,
and su.

### Changed

- esp_loginsight - Updates for parsing

## 1.8.16 (2022-06-29)

This version updates the ElasticDataCollector to run under python3 and use
pySNMP instead of net-snmp.

### Added

- PYSnmpWorker.py - New worker class to handle PySNMP calls

### Changed

- installElasticDataCollector.sh - Updated to create and configure python3
  virtialenv
- AppConfigReader.py - updated imports for python3
- CiscoSwitch.py - Updates for python3 and to use new get_pysnmpdata method
- configurator.py - import updates for python3
- constancts.py - Added new DEVICE_PYSNMPTMOUT for pySNMP calls
- Crypt.py - updated to deal with string being unicode by default in python3
- DataDomain.py - Updates for python3 and to use new get_pysnmpdata method
- DellIdrac.py - Updates for python3 and to use new get_pysnmpdata method
- Device.py - Added new get_pysnmpdata method
- DeviceInfo.py - Removed unused import
- Document.py - Added new static method json_default used by json_dumps
- elasticDataCollector.py - Updated to validate running in python3 environment
- Fx2.py - Updates for python3 and to use new get_pysnmpdata method
- GroupConfigReader.py - import updates for python3
- Isilon.py - Updates for python3 and to use new get_pysnmpdata method
- updatepasswd.py - updated to deal with python3 unicode default
- Vsphere.py - Updates for python3, remove NoneType
- Xtremio.py - Updates for python3, replace all long with int
- Jenkinsfile - Remove creation of oadcgs-es-elastic-domainController-GPO
  artifact
- job.sh - updated to create pysnmp_device_mibs.tar and python3_modules.tar
- MIB_files - Updated with new pysnmp MIB files compiled as .py
- Python_Modules - Updated with all modules needed for python3 virtualenv

## 1.8.15 (2022-06-28)

This version updates the filebeat-7.16.3-auditd-log-pipeline file to expect one
or more spaces in between fields rather than the " " that was the default.

### Changed

- filebeat-7.16.3-auditd-log-pipeline - Regex was added to handle one or more
  spaces in the "Field split" setting

## 1.8.14 (2022-06-22)

This version updates load_roles.sh script to update the index patterns to
current naming standards. It also removes the SIEM privilege from
dcgs_kibana_user

### Changed

- load_roles.sh - Standardizes index pattern naming conventions and removes SIEM
  role from dcgs_kibana_user role

## 1.8.13 (2022-06-21)

This version changed the "upgrade_logstash.sh" script to remove the
heartbeat.yml, run "puppet agent -t" and restart the hearbeat service on the
oadcgs-es-elastic repo. Also copies the geo location, name, monitor ip and agent
name and places the information into the corresponding observer fields.

### Changed

- upgrade_logstash.sh script: Removed heartbeat.yml
- upgrade_logstash.sh script: Added puppet agent -t
- upgrade_logstash.sh script: Added restart heartbeat-elastic if statement on
  lines 65-72
- esp_heartbeat: Copies geo information to the observer fields

## 1.8.12 (2022-06-15)

This version adds a new directory called ingest_pipelines which stores all
7.16.3 filebeat ingest pipelines. It also adds a new utility script called
pull_ingest_pipelines.sh which loads ingest pipelines in elastic, then pulls
ingest pipelines and stores them in the new directory. It also adds
update_ingest_pipeline.sh which loads all pipelines in ingest_pipelines to
Elasticsearch.

### Added

- update_ingest_pipelines.sh - Updates Ingest pipelines in Elastic
- pull_ingest_pipelines.sh - Loads ingest pipelines to elastic node, then pulls
  nodes down into ingest_pipelines directory.
- ingest_pipelines - directory that stores ingest pipelines
- 7.16.3 ingest pipelines added:
  - filebeat-7.16.3-auditd-log-pipeline
  - filebeat-7.16.3-elasticsearch-audit-pipeline
  - filebeat-7.16.3-elasticsearch-deprecation-pipeline
  - filebeat-7.16.3-elasticsearch-gc-pipeline
  - filebeat-7.16.3-elasticsearch-server-pipeline
  - filebeat-7.16.3-elasticsearch-slowlog-pipeline
  - filebeat-7.16.3-iptables-log-pipeline
  - filebeat-7.16.3-logstash-log-pipeline
  - filebeat-7.16.3-logstash-slowlog-pipeline
  - filebeat-7.16.3-system-auth-pipeline
  - filebeat-7.16.3-system-syslog-pipeline
  - filebeat-7.16.3-elasticsearch-audit-pipeline-json
  - filebeat-7.16.3-elasticsearch-deprecation-pipeline-json
  - filebeat-7.16.3-elasticsearch-server-pipeline-json
  - filebeat-7.16.3-elasticsearch-slowlog-pipeline-json
  - filebeat-7.16.3-logstash-log-pipeline-json
  - filebeat-7.16.3-logstash-slowlog-pipeline-json
  - filebeat-7.16.3-elasticsearch-audit-pipeline-plaintext
  - filebeat-7.16.3-elasticsearch-deprecation-pipeline-plaintext
  - filebeat-7.16.3-elasticsearch-server-pipeline-plaintext
  - filebeat-7.16.3-elasticsearch-slowlog-pipeline-plaintext
  - filebeat-7.16.3-logstash-log-pipeline-json-plaintext
  - filebeat-7.16.3-logstash-slowlog-pipeline-plaintext

## 1.8.11 (2022-06-13)

This version updates the linux-syslog pipeline to further parse data and ensures
other data (iptables and audit) is being forwarded to the proper indices.

### Changed

- esp_linux_syslog - Standardizes log.level data. Removes units from integer
  fields. Sends malformed data to it's own index. Sends iptable data to the
  dcgs-iptables index. Sends audit data to the dcgs-audits_syslog index. Cleans
  up debugging fields. Parses json documents.
- bootstrap_indexes.sh - Added iptables and audit indexes to be bootstrapped.
- load_templates.sh - Added iptables and audit templates to be bootstrapped.
- esti_dcgs-syslog - Index template for syslog data
- estc_syslog-mappings - Modified fields as needed
- esti_audit - Index template for audit data
- estc_audit-mappings - Modified fields as needed
- esti_dcgs-iptables - New index template for iptables data
- estc_iptables-mappings - Modified fields as needed

## 1.8.10 (2022-06-10)

This version updates ILM policies and indicies to use new data node attributes.

### Changed

- load_ILMPolicy.sh - Changed from min 35d to 90d, removed box.type attribute
- upgrade_node.sh - Now uses node.roles [ data_content, (data_hot or data_warm)
  ]

## 1.8.9 (2022-06-07)

This version changes all of the pipelines so that they contain geo location and
name.

### Changed

- esp_eracent_database - added a new field and translate portion in the code
- esp_filebeat - added a new field and translate portion in the code
- esp_filebeat-logstash - added a new field and translate portion in the code
- esp_filebeat-syslog - added a new field and translate portion in the code
- esp_hbss_epo - added a new field and translate portion in the code
- esp_hbss_metrics - added a new field and translate portion in the code
- esp_heartbeat - added a new field and translate portion in the code
- esp_idm_database - added a new field and translate portion in the code
- esp_linux_syslog - added a new field and translate portion in the code
- esp_loginsight - added a new field and translate portion in the code
- esp_metricbeat - added a new field and translate portion in the code
- esp_postgres - added a new field, changed format issues, and added translate
  portion in the code
- esp_puppet_database - added a new field and translate portion in the code
- esp_sccm_database - added a new field, added DCGS_site, and added translate
  portion in the code
- esp_sqlServer_Stats - added a new field and translate portion in the code
- esp_winlogbeat - added a new field and translate portion in the code

## 1.8.8 (2022-06-02)

This version adds an environment variable to /etc/sysconfig/logstash. This
variable will reflect the current version of logstash.

### Changed

- upgrade_logstash.sh - Add environment variable VER

## 1.8.7 (2022-06-02)

This version updates the temp_value field to add "ignore_malformed" :true to the
estc_isilon-mappings component template to ingnore the malformed values.

### Changed

- estc_isilon-mappings - added "ignore_malformed" :true to temp value field

## 1.8.6 (2022-05-25)

This version updates the existing database indexes to the new DCGS naming
convention. Old linux templates are removed since they will now be dynamically
created in the upgrade_logstash script and loaded in the load_templates script.
The esp_linux_syslog pipeline now sends data to the dcgs-syslog-iaas-ent-<site>
index.

### Changed

- load_templates.sh - Loads new esti_dcgs-syslog index
- upgrade_logstash.sh - Bootstraps the dcgs-syslog-iaas-ent index. Creates index
  template for site-specific indexes.
- esp_linux_syslog - Now sends data to dcgs-syslog-iaas-ent-${SITENUM}

## 1.8.5 (2022-05-25)

This version changes the esp_sqlServer_stats pipeline and the esti_sqlserver
index template to match the new naming convention. It also updates
reindex_renames_indices.sh to reflect these changes. It also updates
update_logstash_pipelines to avoid writing over user defined pipelines.

### Changed

- esp_sqlServer_stats - changes the pipeline to write to the new
  dcgs-db_sqlserver-iaas-ent index
- esti_sqlsever - changes the rollover alias to dcgs-db_sqlserver-iaas-ent and
  the index pattern to dcgs-db_sqlserver-iaas-ent\*
- reindex_renamed_indices.sh - adds line to reindex sqlserver indices to
  dcgs-db_sqlserver-iaas-ent indices
- bootstrap_indexes.sh - adds dcgs-db_sqlserver-iaas-ent index
- update_logstash_pipelines.sh - adds code to pull down the esp_sqlServer_stats
  pipeline, change the index it writes to to the new convention, and pushes it
  to kibana

## 1.8.4 (2022-05-23)

This version brings updates to the loginsight pipeline to handle multi-line
events. The pipeline has also been updated for better parsing and sending audit
data to the dcgs-audits_syslog-iaas-ent index after being processed by the
filebeat audit ingest pipeline. Updates to bootstrap_indexes to ensure each
index has an is_write_index=true are also included.

### Changed

- esp_loginsight - Handle multi-line and parsing improvements
- bootstrap_indexes.sh - ensure is_write_index=true alias for every index
- reindex_renamed_indices.sh - fix incorrect array creation

## 1.8.3 (2022-05-23)

This version changes the name of the idm name in the esp_idm_database pipeline,
the esti_idm template, and the reindex_renamed_indices.sh files to the new
dcgs-db_idm naming convention.

### Changed

- esp_idm_database: changed the name of idm to dcgs-db_idm-iaas-ent
- esti_idm: changed the name of idm to dcgs-db_idm-iaas-ent
- reindex_renamed_indices: added a new line to allow the new idm reindex
- boostrap_indexes: changed the name of idm to dcgs-db_idm-iaas-ent

## 1.8.2 (2022-05-20)

This version adds a transform and a mutate filter to add coordinates to every
document.

### Changed

- esp_postgres: added coordinate transform geo.location and geo.name
- sites.yml: updated site names
- estc_dcgs_defaults: added geo.name keyword and geo.location geo-point
- update_logstash_pipelines.sh: added esp_postgres

## 1.8.1 (2022-05-18)

This version changes the name of the esp_hbss_syslogs pipeline to esp_hbss_epo
and changes the name of the esti_hbss-syslogs and estc_hbss-syslogs-mappings
templates to esti_hbss-epo and estc_hbss-epo-mappings, respectively. It also
updates load_templates.sh, bootstrap_indexes.sh, update_logstash_pipelines.sh to
reflect these name changes.

### Changed

- load_templates.sh: updated to load the renamed templates
- bootstrap_indexes.sh: updated to bootstrap the new index
- update_logstash_pipelines.sh: updated to update the renamed pipeline

### Added

- esp_hbss_epo: updated to write to dcgs-hbss_epo-iaas-ent index
- estc_hbss-epo-mappings
- esti_hbss-epo: rollover alias changed to dcgs-hbss_epo-iaas-ent, component
  template changed to estc_hbss-syslogs-mappings

### Removed

- esp_hbss_syslogs
- estc_hbss-syslogs-mappings
- esti_hbss-syslogs

## 1.8.0 (2022-05-18)

This feature includes the new dcgs-audits_syslog index which contains linux and
log insight audit data. Also included are the index template and two component
templates. One component template is for generic audit data and one is for
custom log insight audit fields.

### Changed

- bootstrap_indexes.sh - Added in the new dcgs-audits_syslog index

### Added

- estc_audit-mappings - New mappings file for audit fields
- estc_loginsight-agent-mappings - New mappings file for Log Insight Agent field
  mappings
- esti_audit - New index file that is composed of dcgs_defaults, audit-mappings,
  and loginsight-agent-mappings

## 1.7.1 (2022-05-17)

This version changes the name of the sccmdb name in the esp_sccmdb pipeline, the
esti_sccmdb template to the new dcgs-db_sccm naming convention, and adds
reindex_renamed_indices.sh to allow reindexing for different pipelines.

### Changed

- esp_sccm_database - Changed the old name of sccmdb to dcgs-db_sccm-iaas-ent
- esti_sccmdb - Changed two names from sccmdb to dcgs-db_sccm-iaas-ent

### Added

- reindex_renamed_indices.sh - New shell script file to allow reindexing
  pipelines that is a simple template to follow when adding new names that need
  to be reindexed

## 1.7.0 (2022-05-16)

Added Postgres index templates, pipeline and updated install scripts.

### Changed

- bootstrap_indexes.sh - add dcgs-db_postgress-iaas-ent index
- update_logstash.sh - add index templates for postgres esti_db_postgres and
  estc_db_postgres-mappings
- load_pipelines.sh - add esp_db_postgres pipeline

### Added

- esti_db_postgres - New index template for postgres status
- estc_db_postgres-mappings - New postgres status component mappings
- esp_db_postgres - New pipeline for postgres status

## 1.6.9 (2022-05-09)

This version sets the time of event.ingested from the esp_winlogbeat pipeline to
the current time.

### Changed

- esp_winlogbeat - removed line setting the time field of event.ingested to
  @timestamp, added code to set the time field to Time.now().

## 1.6.8 (2022-04-27)

This version adds a new pipeline (esp_filebeat-syslog) to handle data sent from
new syslog server. After parsing the data is sent into the dcgs-syslog-iaas-ent
index. The pipeline also splits out audit and iptables data embedded in the
syslog data into their own indexes dcgs-audit-iaas-ent and
dcgs-iptables-iaas-ent.

### Changed

- estc_syslog-mappings - added in newly-parsed fields
- esti_dcgs-syslog - index template for new filebeat-syslog data
- esp_filebeat-syslog - to fully parse all incoming parseable syslog data

## 1.6.7 (2022-04-26)

Created load_SLM_Policy.sh and remove_Curator.sh. load_SLM_Policy checks for the
existing slm repo and then loads 6 SLM Policies to Elasticsearch if needed.
Remove_Curator.sh removes the current existing curator. The 6 indicies are
dcgs-syslog, winlogbeat, dcgs-hbss_epo, dcgs-db, dcgs-vsphere, and
.siem-signals.

## 1.6.6 (2022-04-25)

Initial postgres monitoring integration

### Changed

- appsconfig.ini - added Postgres section with postgres hosts

## 1.6.5 (2022-04-22)

Reformatted the pipeline files in /pipelines to be in human readable format.
get_pipeline.sh was create and has the utility funciton to pull a pipeline that
was passed in as a command line parameter. It will sed the pipeline to be human
readable then remove the first instance of "id" and "username" so that the
pipeline can be updated using the update_logstash_pipelines.sh and
load_sitebased_pipelines.sh update_logstash_pipelines.sh and
load_sitebased_pipelines.sh were updated to have a sed command that allows them
to change the format back to kibana readable.

## 1.6.4 (2022-04-19)

Changed the name of dcgs-puppet-iaas-ent to dcgs-db_puppet-iaas-ent for the
esp_pipelines_database file in pipelines, changed the names in the templates
file from dcgs-puppet-iaas-ent to dcgs-db_puppet-iaas-ent, and changed the name
dcgs-puppet-iaas-ent to dcgs-db_puppet-iaas-ent in bootstrap_indexes.sh

## 1.6.3 (2022-04-19)

Changed the name of dcgs-eracent-iaas-ent to dcgs-db_eracent-iaas-ent for the
esp_eracent_database file in pipelines and changed the names in the templates
file from dcgs-eracent-iaas-ent to dcgs-db_eracent-iaas-ent

## 1.6.2 (2022-04-07)

Removed the depricated SITENAME variable

## 1.6.1 (2022-04-04)

Added additional sccm dictionary and processing

### Changed

- esp_sccm_database - added processing

## 1.6.0 (2022-03-22)

Move dictionaries to oadcgs-es-puppet-elastic-servers module

### Changed

- dictionaries, patterns - removed directories
- mcafee_eventids.yml - moved to servers puppet module
- sccm_message_ids.yml - moved to servers puppet module
- windows_ids.yml - moved to servers puppet module
- upgrade_logstash.sh - removed copydictionaries function

## 1.5.5 (2022-07-31)

This version contains minor updates to installation scripts to resolve issues
found during installation in the CTE environment

### Changed

- upgrade_logstash.sh - Change prompt to suggest isec instead of cte for test
  install
- upgrade_node.sh - Add data_content to nodes and also add setting to disable
  ccs montitoring
- configurator.py - Show passwords during creation of configurations for easier
  install
- Document.py - Add new "Invalid" option for License
- Isilon.py - Update code to handle invalid/missing license

## 1.5.4 (2022-06-06)

This version contains minor updates to installation scripts to resolve issues
found during installation in the MTE environment

### Changed

- esti_idm - component template name corrected
- installMetricbeatkeystore.sh - Additional error checking added and timing of
  creation of password updated
- update_logsash_pipelines.sh - name of eracent pipeline corrected
- upgrade_node.sh - typo corrected for use_snapshots, security.cookieName added
  and line to ensure python-requests module available added

## 1.5.3 (2022-03-28)

This version adds an update for configuring X11-Fowarding on the Logstash VM to
allow the device configuration tool be displayed. The timeout for rest requests
has also been increased to 60 seconds.

### Changed

- installElasticDataCollector.sh - Disable puppet for install and use sed to
  turn on X11-Forwarding
- Device.py - Increase timeout for rest requests to 60 seconds

## 1.5.2 (2022-03-09)

This version has final updates made before the 7.16.3 release.

### New

- sccm_message_ids.yml - New dictionary used by esp_sccm pipeline
- esp_filebeat-syslog - New pipeline to received data directly from syslog
  servers
- esp_hbss_metrics - Renamed from esp_hbss_epo
- esti_hbss-metrics - Renamed from esti_hbss-epo
- estc_hbss-metrics-mappings - Renamed from estc_hbss-epo-mappings
- esti_syslog - New basic template for syslog server ingest

### Changed

- bootstrap_indexes.sh - updated name for hbss-metrics and added dcgs-syslog
  indexes
- installElasticDataCollector.sh - Updated to not overwrite ini files if they
  already exist
- load_templates.sh - updated hbss template names and added syslog template
- update_logstash_pipelines.sh - updated hbss template names and added syslog
  template
- upgrade_logstash.sh - install fresh dictonaries on every upgrade

### Removed

- esp_hbss_epo - renamed to esp_hbss_metrics
- estc_hbss-epo-mappings - renamed to estc_hbss-metrics-mappings
- esti_hbss-epo - renamed to esti_hbss-metrics

## 1.5.1 (2022-02-26)

Update kibana.yml and elasticsearch.yml to address deprecation warning messages

### Changed

- upgrade_node.sh - Removed settings to clean up deprecation errors
- upgrade_node.sh - Set up logging appenders to replace of
  'server.publicBaseUrl' to kibana.yml
- upgrade_node.sh - Set default logging to logging.root.level to info
- elasticsearch.yml - Set indices.recovery.use_snapshots to false
- action.yml - Remove spacing in filters value
- upgrade.py - Change to support sites

## 1.5.0 (2022-02-25)

This version contains fixes to handle memory leaks found in the netsnmp python
module. Updates to the elasticDataCollector have been made to allow all SNMP
requests to be handled by an SnmpWorker function that runs in its own process
space. There have also been updates to move all config/data files into a new
"data" directory under the scripts directory. The installDataCollector script
was also updated to be used on all future upgrades, the script now removes all
old python code before installing to insure the latest updates are installed and
no old code is left behind.

### New

- SnmpWorker.py - New function to preform SNMP request

### Changed

- installElaticDataCollector.sh - Updated to be used for all installs and
  preform cleanup
- upgrade.py - Don't create metrics_in directory if already there
- configurator.py - change default SNMP timeout to 5 seconds
- constants.py - Add contants to cleanup code and use new datadir
- Device.py - Remove refrences to netsnmp and use new SnmpWorker function
- elasticDataCollectory.py - Remove constants strings from code
- Querier.py - Remove constant strings from code
- README.txt - Updated with new classes/function
- Vsphere.py - Updated to handle error on connection
- Watcher.py - Remove constant strings from code
- Xtreamio.py - Remove constant strings from code
- PYTHON_Modules - Add new python module dependencies

## 1.4.24 (2022-02-10)

This version includes updates found during testing the upgrade of elastic to
version 7.16.3

### New

- patterns - Directory to hold logstash pattern files

### Changed

- load_beats_db.sh - Added overwrite=true to ensure lastest version of dashboard
  is loaded
- load_templates.sh - Hide output when trying to delete obsolete templates
- upgrade.py - Add missing python module imports
- upgrade_logstash.sh - Updates to allow script to exit user enters incorrect
  password and improved notifications
- upgrade_node.sh - Addition of 'server.publicBaseUrl' to kibana.yml
- install_beats_windows.ps1 - Increase sleep after unzip and allow service to
  restart on failure

## 1.4.23 (2022-01-24)

This version includes changes to jvm.options to allow the system to allocate
java heap memory.

### Changed

- upgrade_node.sh - Update jvm.options

## 1.4.22 (2022-01-20)

This version generalizes some of the installation scripts so they can be used
for upgrades to any elastic version. Scripts that are no longer needed were
removed and the idm templates renamed to match current naming conventions.
Templates needed for the upgrade to Elastic version 7.16.3 are also added.

### Changed

- bootstrap_indexes.sh - updated so it can be used for all upgrades
- load_templates.sh - upgraded so it can be used for all upgrades
- upgrade_logstash.sh - upgraded so it can be used for all upgrades
- installMetricbeatkeystore.sh - updated to prompt user to move on if
  metricbeat-user exists
- esti_idm-template - renamed to esti_idm
- estc_idm-template-mappings - renamed to estc_idm-mappings

### Deleted

- bootstrap_hs_indexes.sh - No longer needed, use bootstrap_indexes.sh
- bootstrap_indexes-7.12.sh - No longer needed, use bootstrap_indexes.sh
- bootstrap_indexes-7.16.sh - No longer needed, use bootstrap_indexes.sh
- load_hs_templates.sh - No longer needed, use load_templates.sh
- load_templates-7.12.sh - No longer needed, use load_templates.sh
- load_templates-7.16.sh - No longer needed, use load_templates.sh
- esti_device-settings - No longer used
- estc_filebeat-7.16.1-mappings - No longer needed
- estc_heartbeat-7.16.1-mappings - No longer needed
- estc_metricbeat-7.16.1-mappings - No longer needed
- estc_winlogbeat-7.16.1-mappings - No longer needed

### New

- estc_filebeat-7.16.3-mappings - filebeat mappings for 7.16.3
- estc_heartbeat-7.16.3-mappings - heartbeat mappings for 7.16.3
- estc_metricbeat-7.16.3-mappings - metricbeat mappings for 7.16.3
- estc_winlogbeat-7.16.3-mappings - winlogbeat mappings for 7.16.3
- esti_filebeat-7.16.3 - filebeat index template for 7.16.3
- esti_heartbeat-7.16.3 - heartbeat index template for 7.16.3
- esti_winlogbeat-7.16.3 - winlogbeat index template for 7.16.3

## 1.4.21 (2022-01-20)

This version includes additions of the Vsphere index and component template
mappings.

### New

- esti_vsphere - Vsphere index template
- estc_vsphere-mappings - Vsphere component mappings

## 1.4.20 (2022-01-18)

Update legacy node role definitions to newer node.roles array definition

### Changed

- upgrade_node.sh - Update node roles
- upgrade.py - Update to allow passing user and password into update.py

## 1.4.19 (2022-01-12)

This version adds the ability to received event data from each vcenter host
using the vsphere api. A new Vsphere class is added to the elasticDataCollector
to run in it's own thread to query event data. The esp_puppet_database pipeline
is also added which queries audit events from the puppet postgresql database.

### New

- esp_puppet_database - new pipeline to query puppet postgresql database
- updatepasswd.py - Script to query password needed to use vsphere api
- Vsphere.py - New class used to query data from vcenter using vsphere api

### Changed

- installElasticDataCollector - Add pyVmomi module during installation
- load_pipelines.sh - remove changes made for new pipelines, this script was for
  7.9.1 only
- update_logstash_pipelines.sh - Add new pipelines
- constants.py - Add VSPHERE_DAT file location which holds encrpted vsphere
  authentication information
- Document.py - Add new VSPHERE DocSubType for vcenter events
- elasticDataCollector - Add new thread for Vsphere class
- PYTHON_Modules - Add pyVmomi module

## 1.4.18 (2022-01-05)

This version includes additions of the puppet index and component template
mappings.

### New

- esti_puppet - Puppet index template
- estc_puppet-mappings - Puppet component mappings

## 1.4.17 (2022-01-05)

Baseline hbss-epo pipeline and templates

### New

- esp_hbss_epo
- estc_hbss-epo-mappings
- esti_hbss-epo

### Changed

- load_hs_templates.sh
- load_pipelines.sh

## 1.4.16 (2022-01-04)

This version adds the postgresql jdbc driver to support queries to postgres
databases. The new jdbc driver is installed when doing a Logstash upgrade.

### New

- postgresql-42.3.1.jar - postgresql jdbc driver

### Changed

- upgrade_logstash.sh - ensure all jdbc drivers are up to date on upgrade

## 1.4.15 (2021-12-15)

This version contains updates to the sccm pipeline and component template
mappings. There are also minor changes to the eracent pipeline to preserve the
logstash document creation time.

### Changed

- esp_eracent_database - Updates to preseve logstash document creation time
- esp_sccm_database - Updates to use ECS fields for ingested data
- estc_sccmdb-mappings - Template changes for new ECS fields
- estc_eracent-mappings - Add meta data to component template

## 1.4.14 (2021-12-15)

This version adds a idleTimeout and lifeSpan for Kibana sessions

### Changed

- upgrade_node.sh - If Kibana installed on node add session timout values to
  config

## 1.4.13 (2021-12-14)

This version addes the esp_eracent pipeline to query data from the eracent
database.

### New

- esp_eracent_database - Eracent logstash pipeline
- esti_eracent - Eracent index template
- estc_eracent-mappings - Eracent component template mappings

### Changed

- load_hs_templates.sh - Added loading of new eracent templates
- load_pipelines.sh - Added loading of new eracent pipeline

## 1.4.12 (2021-12-14)

- Create component mappings for beats templates and install by script
- Create script to install beats index and component templates
- Create script to bootstrap beats

## 1.4.11 (2021-12-13)

- Update to the upgrade_node script to include the USG warning banner at the
  Kibana login screen if not already in place

## 1.4.10 (2021-12-03)

- Update loginsight pipeline to parse more data
- Update loginsight component template to map the new fields that were created

## 1.4.9 (2021-11-30)

- Update linux-syslog to component templates
- Update curator actions for linux-syslog
- Add estc_linux-syslog-mappings, esti_linux_syslog, and remove est_linux_syslog
  to install scripts

## 1.4.8 (2021-11-22)

- Clean up estc_idm-template-mappings - only include needed mappings
- Add reindex_templates.sh to reindex idm indices

## 1.4.7 (2021-11-18)

Updates to make csr script to ensure keyUsage and extendedUsage in in request

### Changed

- make_elastic_csrs.sh - uncomment out keyUsage and extendedKeyUsage attributes
- make_logstash_csr.sh - uncomment out keyUsage and extendedKeyUsage attributes

## 1.4.6 (2021-11-12)

Rename templates to index or component for easy identification

## 1.4.5 (2021-11-08)

This version contains updates to install scripts used for site Logstash
instances to allow them to communicate with the elastic cluster correctly.
Update to the Querier class to only request hosts for the site it's runing from
are also included.

### Changed

- installElasticDataCollector.sh - Updates to communicate with cluster correctly
  and create clusterSite.dat file for use by data collector script
- upgrade_logstash.sh - Updates to communicate with cluster correctly and create
  metrics_in directory need by new esp_metricbeat pipeline
- constants.py - Added new CLUSTER_SITE constant
- Querier.py - Updates to SQL query to only ask for hosts from site where script
  is running. Also fixes to communicate with cluster correctly

## 1.4.4 (2021-11-01)

Convert DCGS Legacy templates to component templates

## 1.4.3 (2021-10-29)

Updated the windows event dictionary

### Changed

- windows_id.yml - added more event ids and definitions

## 1.4.2 (2021-10-26)

This version contains updates to ensure ILM polices work correctly for site
based indexes and a template change for device data so current ingest data is
written to hot nodes. A update was also made to the CiscoSwitch class of the
elasticDataCollector to handle missing fields in a response.

### Changed

- est_device-settings - Ensure all ingest for device data goes to hot nodes
- upgrade_logstash.sh - Add site based templates for ILM rollover_alias setting
- CiscoSwitch.py - Add try/except to handle possible missing fields in response

## 1.4.1 (2021-10-08)

Update pipelines with DCGS_Site_Name an add sites list

## 1.3.24 (2021-10-26)

This version contains updates to install scripts used for site Logstash
instances to allow them to communicate with the elastic cluster correctly.
Update to the Querier class to only request hosts for the site it's runing from
are also included.

### Changed

- installElasticDataCollector.sh - Updates to communicate with cluster correctly
  and create clusterSite.dat file for use by data collector script
- upgrade_logstash.sh - Updates to communicate with cluster correctly and create
  metrics_in directory need by new esp_metricbeat pipeline
- constants.py - Added new CLUSTER_SITE constant
- Querier.py - Updates to SQL query to only ask for hosts from site where script
  is running. Also fixes to communicate with cluster correctly

## 1.3.23 (2021-10-26)

This version contains updates to ensure ILM polices work correctly for site
based indexes and a template change for device data so current ingest data is
written to hot nodes. A update was also made to the CiscoSwitch class of the
elasticDataCollector to handle missing fields in a response.

### Changed

- est_device-settings - Ensure all ingest for device data goes to hot nodes
- upgrade_logstash.sh - Add site based templates for ILM rollover_alias setting
- CiscoSwitch.py - Add try/except to handle possible missing fields in response

## 1.3.22 (2021-10-05)

Updates were made to modifiy metricbeat and linux_syslog high volume indexes to
be site based during the upgrade process. After upgrading to 7.12.1 these two
indexes will be per site.

More error checking was also added to the elasticDataCollector to protect it
from issues where data may be missing.

### New

- load_sitebased_pipelines.sh - New script to load site based pipelines

### Changed

- esp_linux_syslog - Pipeline modified to add site number onto index
- esp_metricbeat - Pipeline modified to add site number onto index
- update_logstash_pipelines.sh - removed metricbeat and linux_syslog, now site
  based
- upgrade_logstash.sh - Updated to bootstrap site based indexes for each
  Logstash site
- elasticDataCollector.py - Added code to catch execptions caused by invalid
  data
- README.txt - Added new script to Readme

## 1.3.21 (2021-09-29)

Updates were made to handle REST requests to devices that return simi successful
results. The HTTP return code 207 is a multi-status return code that can have
sucessful and failed results.

### Changed

- Device.py - Handle 207 response code
- Isilon.py - process partially successful result

## 1.3.20 (2021-09-23)

Updates to README.txt to show all additions for 7.12.1 upgrade

## 1.3.19 (2021-09-21)

updated upgrade_logstash and upgrade_node script to add updates to log4j
properties config file during the logstash and elasticsearch upgrades.This
update will limit the amount of log files we have in /var/log/elasticsearch and
/var/log/logstash.

### Changed

- Added lines 67 through 70 in the upgrade_logstash.sh script to add a delete
  action in the default logstash log4j2 configurations
- Added lines 76 through 79 in the upgrade_node.sh script to remove a character
  in the default elasticsearch log4j2 configurations

## 1.3.18 (2021-09-21)

This version included final updates in preparation for the MVP RFC submittal

### New

- savedObjects_7.12.ndjson - all dashboard, visuals and other objects for MVP
  release
- remove_7.9.1_objects.sh - Script to remove visuals/dashboards installed with
  7.9.1

### Changed

- esp_filebeat - added creation of DCGS_Site field for all filebeat documents
- esp_linux_syslog - Updated to remove auditd.log.addr if it is set to "UNKNOWN"
- esp_metricbeat - Update pipeline workers to 8
- installElasticDataCollector.sh - Ensure MIBS dir has correct permissions
- update_logstash_pipelines.sh - Updated to load all pipelines as named
- upgrade_node.sh - add path.repo to all elasticsearch.yml files during upgrade
- appmonitor_win.js - Lowercase all process/services and update check for
  undefined service/process
- install_beats_windows.ps1 - Ensure all beats services are delayed autostart
- constants.py - Upadate GRPS_CONF and DEVICE_MIBSDIR values
- DellIdrac.py - Add fix to remove special characters if present i
  virtualDiskName
- Isilon.py - Add error checking so communications issues don't cause thread to
  exit
- Jenkinsfile - Return condition to only publish to Nexus on master branch
- job.sh - Removed copying of Crypt.py, this file is now added to
  curatorConfig.tar

### Removed

- InfraMon.ndjson - replaced with savedObjects_7.12.ndjson
- groups.ini - moved to scripts/install directory
- load_hs_objects.sh - Script replaced with load_7.12_objects.sh

## 1.3.17 (2021-09-17)

Added curator to enable archiving for indexes.

### New

- curator - directory for the curator configuration files and run script
- configuration.yml - the configuration file contains client connection and
  settings for logging
- action.yml - actions are the tasks which Curator can perform on your indices.
- installCurator.sh - installs the curator tool
- runcurator.sh - bash script that runs the curator

## 1.3.16 (2021-09-16)

- Added appsconfig-site.ini
- Modified installElasticDataCollector to install hub or site appsconfig.ini
- Set permissions on MIBS dir

## 1.3.15 (2021-09-14)

Added metricbeat yml files to monitor Password Manager and OneIM
(wb01.metricbeat.yml and jb01.metricbeat.yml).

Added metricbeat yml files to monitor AD-DNS (dc01.metricbeat.yml and
dc02.metricbeat.yml). Also added updated appsconfig.ini to include AD-DNS
machines.

## 1.3.14 (2021-09-10)

Update upgrade_node.sh to enable Metricbeat monitoring for Kibana Fix typo in
installMetricbeatkeystore.sh

## 1.3.13 (2021-09-09)

Updated installElasticGPO.ps1

- Add -ExecutionPolicy Bypass -file and update path

## 1.3.12 (2021-08-27)

Multiple changes were added in this version

- Multiple script update to support 7.12.1 installation
- Creation of new oadcgs-es-elatstic-domainController-GPO artifact on Nexus with
  Master build
- Correction to McAfee Agent and Endpoint monitoring

### Changed

installElasticDataCollector.sh - add new directory for ini config files
installMetricbeatkeystore.sh - cleaned up user messages upgrade.py - ensure file
permissions after upgrade appmonitor_win.js - Added new feature to monitor
process with cmdline args hb10.metricbeat.yml - updates to correct McAfee
monitoring hb11.metricbeat.yml - updates to correct McAfee monitoring
metricbeat.yml - updates to correct McAfee monitoring sc01.metricbeat.yml -
updates to correct McAfee monitoring sc02.metricbeat.yml - updates to correct
McAfee monitoring sc03.metricbeat.yml - updates to correct McAfee monitoring
sc04.metricbeat.yml - updates to correct McAfee monitoring sc05.metricbeat.yml -
updates to correct McAfee monitoring sc06.metricbeat.yml - updates to correct
McAfee monitoring appsconfig.ini - moved to new intstall directory groups.ini -
moved to new install directory DataDomain.py - updated to fix issue with time
not updating on query error job.sh - updated to create new Nexus artifact for
Elastic GPO installation

### New

- update_logstash_pipelines.sh - loads all new and modified pipelines into
  Kibana
- upgrade_logstash.sh - script for upgrading Logstash instance
- update_auditsettings.sh - script to updata audit settings for Elastic
- load_hs_objects.sh - script to load new objects into Kibana
- load_hs_templates.sh - script to load new templates into Elastic
- bootstrap_hs_indexes.sh - script to bootstrap new indexes into Elastic
- est_healthdata - new index template for heath data
- est_healthdata-mappings - new component template for heath data
- elasticGPO - Directory containing script to install new Elastic GPO for Domain
  Controllers and the GPO itself

  - Elastic Metricbeat Install/{465035F7-1532-4275-9B68-047E588CD31C}
  - DomainSysvol/GPO/Machine/Preferences/ScheduledTasks
  - ScheduledTasks.xml
  - Backup.xml
  - bkupInfo.xml
  - installElasticGPO.ps1

### Removed

- esp_filebeat-dataCollector - replaced by esp_filebeat-logstash
- update_logstash_yml.sh - merged into upgrade_logstash.sh script

## 1.3.11 (2021-08-20)

Added HBSS Rogue System Detection machines to configuration Added
hb10.metricbeat.yml, hb11.metricbeat.yml files Modified appconfig.ini for HBSS

## 1.3.10 (2021-08-05)

This version adds that capibility to monitor a group of workstations. The
minimum number of hosts for the group to be considered "OK" is specified in the
configuration.

### Changed

- constants.py - Added Path to group.ini config file and updates location of
  .ini files
- elasticDataCollector.py - Add code to monitory groups
- Group.py - New class to hold group info and determine health
- Document.py - Changes for Groups
- GroupConfigReader.py - Used to read groups.ini file
- groups.ini - New config file for group definition
- esp_filebeat-logstash - updates to pipeline to send Group health documents to
  the dcgs-healthdata index

## 1.3.9 (2021-08-06)

This version contains fixes in the elasticDataCollector to resolve the issue of
devices disappearing from the infrastructure dashboard. Changes were also added
to correct the miscalulation of Application health based on defined effect in
the appsconfig.ini file.

### Changed

- App.py - Update logic to calculate Application health
- CiscoSwitch.py - add mutex to limit writing to 1 instance of Class
- DataDomain.py - add mutex to limit writing to 1 instance of Class
- DellIdrac.py - add mutex to limit writing to 1 instance of Class
- Fx2.py - add mutex to limit writing to 1 instance of Class
- Isilon.py - add mutex to limit writing to 1 instance of Class
- Xtremio.py - add mutex to limit writing to 1 instance of Class
- Host.py - Removed unneeded print statements
- Device.py - Ensure time is set for request, even on timeout or exception
- Outfile.py - Catch any exceptions on writes to ensure thread does not crash
- Crypt.py - Modified main to allow use as utility

## 1.3.8 (2021-08-06)

Correct issue where defined effect was not being evaluated correctly causing
incorrect host healt to be reported. Threshold values for cpu, memory and
filesystem were also added to process_summary document.

### Changed

- appmonitor_win.js - updated hosthealth logic. Also add threshold values to
  process_summary doc.

## 1.3.7 (2021-08-05)

Change memory threshold to 95

### Changed

- metricbeat.yml
- sc01.metricbeat.yml
- sc02.metricbeat.yml
- sc03.metricbeat.yml
- sc04.metricbeat.yml
- sc05.metricbeat.yml
- sc06.metricbeat.yml

## 1.3.6 (2021-08-05)

Add monitoring of Arcsight application

### Changed

- appconfig.ini - Added Arcsight application

## 1.3.5 (2021-07-15)

This version updates the timing for metricsets in the systems module of
metricbeat. A fix to catch an execption when issues occur commuicating with
Elastic in the elasticDataCollector was also added.

### Changed

- Querier.py - added try block to catch exceptions during elastic communction
- all.module.system.yml - Adjusted timing for metricsets 30s - cpu, memory,
  network, socket_summary, core, diskio 1m - process, filesystem, fstat

## 1.3.4 (2021-07-12)

This version has changes to ensure hostnames are lowercased when ingested inot
elasticsearch. Audit exclusions were also added for new applicaton users

### Changed

- esp_metricbeat - Added lowercasing for hostname fields
- esp_filebet-logstash - Added lowercasing for hostname fields
- esp_winlogbeat - Removed testing tag and cleaned up output section
- esp_filebeat - Removed unneeded filtering, cleaned up pipeline
- esp_sccm_database - Added lowercaseing for MachineName field
- esp_idm_database - Added lowercasing for ccc_hostname field
- load_auditsettings.sh - Add audit exclusions for new application users

## 1.3.3 (2021-07-08)

This version adds the "querier-xx" (where xx = site number) user in Kibana for
use by the elasticDataCollector. The new users is created when running the
installElasticDataCollector script during installation and is used by the
Querier class of the elasticDataCollector for communication with Elastic.

A timestamp was also added to documents generated by they Querier class which
are written to querier.json.

## Changed

- installElasticDataCollector - updated to create querier user/password in
  Kibana and store in querier.dat file on Logstash
- Querier.py - Modified to read user/password from QUERIER_DAT file
- constants.py - Added QUERIER_DAT constant to hold user/encrypted password
- Host.py - Added timestamp when instantiating new Document

## 1.3.2 (2021-07-07)

The esp_filebeat-logstash pipeline is new in this version. This pipeline is for
use on Logstash hosts and handles all data sent by the elasticDataCollector.

### NEW

- esp_filebeat-logstash - Pipeline for Logstash hosts.

## 1.3.1 (2021-07-06)

This version contains updates to issues found during upgrade testing

## Changed

- upgrade.py - Added better error checking on http requests
- upgrade_node.sh - removed success message at end of script
- MIB_files - corrected names of MIB Files
- install_beats_windows.sh - Minor updates to resolve timing and path issues

## 1.3.0 (2021-06-15)

This version extends the functionality of the elasticDataCollector to create
health documents for Hosts and Applications.

### Changed

- Removed "id" from esp\_<pipeline> files, not used after 7.9.1
- Updated esp_metricbeat pipleine to process application and metrics information
  passed in process_summary document
- Added virutalenv for elasticDataCollector to run in. Service has been modified
  to run in virutalenv
- job.sh modified to pull python modules named in PYTHON_modules file from Nexus
  to create a python_modules.tar used during install

### New

- appsconfig.ini Configuration file that holds definition of applications to
  monitor
- Host.py Class to hold health information about a host
- App.py Class to hold health information about an application
- Outfile.py Utility class used to write documents to file
- Querier.py Class used to query heartbeat hosts from elasticsearch and check
  health
- Watcher.py Class used to read health data from file and update hosts/Apps
- AppConfigReader.py Utility class used to read ini configuration file
- PYTHON_Modules File containing list of all python modules needed by
  elasticDataCollector

## 1.2.2 (2021-06-03)

Allow metrictbeat to send host statistics from elasticsearch nodes to
elasticsearch

### Changes

installMetricbeatkeystore.sh installLogstash.sh installElasticNode.sh
update_logstash.yml upgrade_node.sh

## 1.2.1 (2021-06-03)

This version adds the capibility of configuring filebeat on a host by detecting
the presense of an application. A config.yml file is created for the application
and is placed in the inputs.d directory of the configs/filebeat directory on the
SCCM share. The application name and config.yml file are added to the inputs.txt
file which holds all applications to look for on hosts.

Also contains minor changes for metricbeat application monitoring

### Changed

install_beats_windows.ps1 - code was modified to copy filebeat configs over to a
host if the application specified in the inputs.txt file is found on the host.

metricbeat.yml - uppercase first letter of down to be conistent with other
effects appmoniotr_win.js - change name of field HealthSymptom to HealthSymptoms
for consistency with Infrastructure documents.

### New

inputs.d - directory to hold filebeat config files filebeat.yml - default
filebeat.yml file with changes to look in inputs.d for configurations
inputs.txt - text file containing information on programs to look for on hosts
and the name of the associated filebeat config in the inputs.d directory

## 1.2.0 (2021-05-17)

This version brings the addtion of host/application monitoring from metricbeat.
A new javaScript processor called appmonitor_win.js has been added to the
deployment of metricbeats to all windows hosts. This new processor adds
host/application health information to the process_summary document generated by
metricbeat. This information will be used by the elasticDataCollector in
upcoming versions.

### Changed

install_beats_windows.ps1 - modified to copy appmonitor_win.js as part of
metricbeat install. Also now allows for metricbeat.yml config based on hostname.
all.module.systtem.yml - Changed polling period to 1m for most metricsets and
created new section for process_summary with peroid of 2m metricbeat.yml - Added
new processors section for App_Monitor

### New

appmonitor_win.js - New javaScript processor for metricbeat

## 1.1.3 (2021-05-11)

This version adds AN-GSQ-272 Headers to Scripts and brings a few minor changes
that will mark devices UNKNOWN if there are errors on requesting data.

### Changed

- Add AN-GSQ-272 Headers to all bash and python scripts
- Add README.txt file in install and scripts directory
- Mark Devices UNKNOWS on communication error

## 1.1.2 (2021-05-05)

This version adds the collection of service information from Windows boxes

### Changed

- Add the windows module for metricbeat installations on Windows boxes to
  collect service information

## 1.1.1 (2021-04-28)

This version is used to upgrade from 7.9.1 to 7.12.1

### Changed

- Upgrade version to 7.12.1
- Added fix to show DellIdrac blades as down if powered off

## 1.1.0 (2021-04-09)

This version is used to upgrade from 7.9.1 to 7.12.0

### Added

- Infrastruction Monitoring with elasticDataCollector

### Changed

- Upgraded Elastic version to 7.12.0

## 1.0.2 (2021-03-27)

This version contains updates for the 7.9.1 installation

- Fix issue found during Logstash install

### Fixed

- installLogtash.sh - Removed lines that were added by what looked like a diff

### Changed

- pipelines - Added "id":"<name>" back into pipleines as this is needed in
  version 7.9.1

## 1.0.0 (2020-10-07))

This version is the initial version for the 7.9.1 installation

### Added

Initial Release
