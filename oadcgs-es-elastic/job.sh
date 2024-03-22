#!/usr/bin/env bash

export VERSION=${VERSION:-0.1.0}
export BUILD_ID=${BUILD_ID:-1}

PREFIX="oadcgs-es-elastic"
BRANCH="HEAD"

NEXUS_URL='https://nexus.di2e.net/nexus3/repository/Private_OADCGS-Infrastructure/Enterprise_Services/External_Files/Elastic/'
MIB_ARTIFACT_ID='Infrastructure_MIBS'
PY_ARTIFACT_ID='Python_Modules'
MIB_VERSION='PySNMP-1.0'
PY_VERSION='2.0'
STAGING='./install/artifacts/staging'
DESTDIR='./install/artifacts'
SCRIPTDIR='./scripts'
CURATORDIR='./curator'
MIBTAR='pysnmp_device_mibs.tar'
PYMODULESTAR='python3_modules.tar'
SCRIPTTAR='elasticDataCollector.tar'
CURATORTAR='curatorConfig.tar'

FILES=(AUTHORS.md CHANGELOG.md README.md)

# create_archive allows archiving of file already commited to the git repo
create_archive() {
  git archive \
    --output=pkg/"${PREFIX}"-"${1}"-"${VERSION}"."${BUILD_ID}"."${3}" \
    --prefix="${PREFIX}"-"${1}"/ --format "${3}" "${BRANCH}" \
    "${FILES[@]}" "${2}"
}

# tar_local_files - Generates tar.zg of all files present in the directory.
#                   Files do not need to be added to git repo.
tar_local_files() {
  tar cvfz pkg/"${PREFIX}"-"${1}"-"${VERSION}"."${BUILD_ID}".tar.gz \
    --transform "s+^+${PREFIX}-${1}/+" "${FILES[@]}" "${2}"
}

package_mibs_from_nexus() {
  # Create staging area and download MIBS from nexus
  mkdir "${STAGING}"
  while read -r mib; do
    if [[ "${mib}" == \#* ]]; then
      continue
    fi
    curl -sL --user "${DI2E_USER}:${DI2E_PASSWORD}" "${NEXUS_URL}/${MIB_ARTIFACT_ID}/${MIB_VERSION}/${MIB_ARTIFACT_ID}-${MIB_VERSION}-${mib}" >>"${STAGING}/${mib}"
  done <./MIB_files

  # Package up the MIB files for distribution
  tar cf "${DESTDIR}"/"${MIBTAR}" --remove-files -C "${STAGING}" .
}

package_python_modules_from_nexus() {
  # Create staging area and download python modules from nexus
  mkdir "${STAGING}"
  while read -r module; do
    if [[ "${module}" == \#* ]]; then
      continue
    fi
    curl -sL --user "${DI2E_USER}:${DI2E_PASSWORD}" "${NEXUS_URL}/${PY_ARTIFACT_ID}/${PY_VERSION}/${PY_ARTIFACT_ID}-${PY_VERSION}-${module}" >>"${STAGING}/${module}"
  done <./PYTHON_Modules

  # Package up the MIB files for distribution
  tar cf "${DESTDIR}"/"${PYMODULESTAR}" --remove-files -C "${STAGING}" .
}

package_data_collector() {
  # Package up the python script for distrubution
  tar cf "${DESTDIR}"/"${SCRIPTTAR}" -C "${SCRIPTDIR}" .
}

package_curator() {
  # Package up the curator directory for distrubution
  cp "${SCRIPTDIR}"/Crypt.py "${CURATORDIR}"/Crypt.py
  tar cf "${DESTDIR}"/"${CURATORTAR}" -C "${CURATORDIR}" .
}

# Package MIBS, Python Modules and Data Collector Python scripts before creating Nexus archives
package_mibs_from_nexus
package_python_modules_from_nexus
package_data_collector
package_curator

# Create archives for Nexus
create_archive "sccm" "sccm" "zip"

tar_local_files "reposerver" "install"
