#!/bin/bash
# Script for injecting SOAESB test data
####Pre-Requisites:
#   - Test files extracted into current directory:
#       - Insert_Testdata.sh    This script
#       - soaesb-test.yml       Filebeat config for running directly
#       - testdata.docker       Test log for Docker/Filebeat
#       - testdata.filebeat     Test log for direct Filebeat
#       - testdata.txt.log      Raw test log content
#   & Either:
#       - Docker running, with a container with "soaesb" in its name or image name
#       - Filebeat runnning with the docker module
#   Or:
#       - Filebeat installed to run manually (/usr/bin/filebeat)

CONTAINER="$(docker ps | grep "soaesb" | sed 's/^\([0-9a-f]*\) .*/\1/')"
if [ -z "${CONTAINER}" ]; then
  echo "Docker container 'soaesb' was not found; using local Filbeat."
  if [ ! -f "./soaesb-test.yml" ]; then
    echo "./soaesb-test.yml must exist"
    exit 1
  fi
  if [ ! -f "./testdata.filebeat" ]; then
    echo "./testdata.filebeat must exist"
    exit 1
  fi
  TESTDATA=./testdata.filebeat
  # Run Filebeat
  /usr/bin/filebeat test config -c /tmp/Bg/dcgs-soaesb.yml
  return=$?
  if [[ $return != 0 ]]; then
    echo "ERROR: Cannot run Filebeat, are you running as root?"
    exit 1
  fi
  read -p "Enter location for log files: " -r LOGDIR </dev/tty
  echo
  read -p "Enter the logstash host, including port: " -r LOGSTASH </dev/tty
  echo
  sed "s-/tmp/logs-${LOGDIR}-" ./soaesb-test.yml | sed "s/localhost:80/${LOGSTASH}/" >"$(pwd)/soaesb-temp.yml"
  /usr/bin/filebeat -c "$(pwd)/soaesb-temp.yml" &
else
  echo "Docker container 'soaesb' found: ${CONTAINER}"
  LOGDIR="/var/lib/docker/containers/${CONTAINER}*"
  if [ "$(systemctl status filebeat | grep -c 'active (running)')" != 1 ]; then
    echo "Filebeat service needs to be running."
    exit 1
  fi
  if [ ! -f "./testdata.docker" ]; then
    echo "./testdata.docker must exist"
    exit 1
  fi
  TESTDATA=./testdata.docker
fi

echo "Ingesting log lines ..."
# Insert todays date into log lines as we copy then into the logs directory;
#  1 line per second (necessary for the aggregate filter).
while IFS= read -r LINE; do
  sleep 1
  echo "$LINE" | (sed "s/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\([ T]\)[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}.[0-9]\{3\}/$(date +'%Y-%m-%d\1%H:%M:%S.%3N')/g" >>"${LOGDIR}/testdata.log")
  echo .
done <"${TESTDATA}"

# Stop Filebeat
if [ -z "${CONTAINER}" ]; then
  echo "... wait, to ensure ingest ..."
  sleep 10
  pkill filebeat
fi

# Cleanup
