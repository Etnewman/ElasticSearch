# OADCGS ES Elastic

This repo contains the scripts used to install Elasticsearch and it's components
on OADCGS

## Features

- Provides installation scripts used during the execution of Elastic
  installation instructions.

      Install Documents:
      "CR-2020-OADCGS-086 - See "ES-018-Elastic Logging and Aggregation Cluster(ELAC)-System Installation Instructions" for more details"
      "CR-2021-OADCGS-078 - See "ES-018-Elastic Logging and Aggregation Cluster(ELAC)-Upgrade to 7.12.1 Instructions" for more details"
      "CR-2022-OADCGS-020 - See "ES-018-Elastic Logging and Aggregation Cluster(ELAC)-Upgrade to 7.16.3 Instructions" for more details"

- Provides template for the creation of the "Install Elastic Beats Windows" SCCM
  Package

      Install Document
      "ES-018 - SCCM - Instructions for Building an SCCM Package to Install Elastic Beats for Windows"

## Installation

The contents of this repo will be compressed into 2 archives which will both be
moved to Nexus.

- oadcgs-es-elastic-reposerver-x.x.x.x.tar.gz - archive of the install directory
  which holds all the installation scripts and data files used while following
  the installation instructions.
- oadcgs-es-elastic-sccm-x.x.x.x.zip - archive of the sccm directory which holds
  the artifacts needed to create the SCCM beat installation package.

Both of these files should be downloaded by the installer and moved into the
**"\\fileserver\admin\ess\elastic\deployment drive"** directory for staging on
the system where the installation is taking place.

## Usage

- The SCCM Admin will extract the contents of the
  oadcgs-es-elastic-sccm-x.x.x.x.zip and use the sccm/shareDir to build the
  "Install Elastic Beats Windows" Package used for installation and Backout of
  beats on Windows machines.

- A Linux or Puppet Admin will copy the
  oadcgs-es-elastic-reposerver-x.x.x.x.tar.gz file to the OADCGS repo server and
  extract it in the elastic repo using the following command:

```
tar -zxf oadcgs-es-elastic-reposerver-x.x.x.x.tar.gz --strip-components=1
```

See [CHANGELOG](CHANGELOG.md)

## Credits

See [AUTHORS](AUTHORS.md)
