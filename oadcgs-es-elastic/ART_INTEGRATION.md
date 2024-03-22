# Integrating an ART into Elastic Baseline

## ART Repo Files

- Copy install/artifacts/_ (e.g. .ndjson files) into install/artifacts/_

- Insert content of install/pipeline/\* (e.g. .filebeat-filter files): If needs
  single-worker - Into install/pipelines/esp_filebeat-singleworker ... Else -
  Into install/pipelines/esp_filebeat (devUtils contains a script
  insertSectionIntoPipeline.sh to insert/modify/remove sections)

- Copy install/templates into install/templates Naming should be estc*/esti*.

If SCCM - Add App line into sccm/shareDir/configs/filebeat/inputs.txt - Copy
sccm/shareDir/configs/filebeat/inputs.d/\* (e.g. .yml files) into
sccm/shareDir/configs/filebeat/inputs.d/

If Puppet - Copy puppet content into puppet-clients repo

- Copy testfiles into install/testfiles, if they are needed to verify the
  install

## Install Scripts

- Ndjson: Add ndjson filename to install/load_objects.sh

- Templates: Add component template and index template to
  install/load_templates.sh

- Bootstrap: add index name to list in install/bootstrap_indexes.sh
