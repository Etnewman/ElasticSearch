scriptDir=/etc/logstash/scripts
LOGSTASH_DATA_DIR="/etc/logstash/scripts/data"
DAT_FILE="$LOGSTASH_DATA_DIR/hbssdlp.dat"
LASTINCIDENTTIME=hbssdlp.last_event_querytime
NO_IDS="{\"incidentIds\":[],\"endTime\":\"null\"}"
results=()

#
# Lets get the data from the dat file
DLP_HOST=$(sed -n '1p' $DAT_FILE)
DLP_PORT=$(sed -n '2p' $DAT_FILE)
user=$(sed -n '3p' $DAT_FILE)
password=$(sed -n '4p' $DAT_FILE)

#
# Use out python environment
# Disable shellcheck for source line because activate script is not part of the baseline
# shellcheck disable=SC1091
source /etc/logstash/scripts/venv/bin/activate
passwd=$(python $scriptDir/Crypt.py -d "$password")
deactivate

#
# if hbssdlp_last_event_query_time.dat exists and has something in it
if [[ -s $LOGSTASH_DATA_DIR/$LASTINCIDENTTIME ]]; then
    # Get startTime from hbssdlp_last_event_query_time.dat
    startTime=$(cat $LOGSTASH_DATA_DIR/$LASTINCIDENTTIME)
else
    #
    # Set startTime to a time in the past
    startTime=$(($(date +%s -d "2 years ago")*1000))
fi
    incidentids=$(curl -k -s -u "${user}":"${passwd}" "https://${DLP_HOST}:${DLP_PORT}/rest/dlp/incidents/ids?startTime=$startTime&incidentNature=1")
    #
    # Create list of incident Ids
    incidentidslist=$(echo $incidentids | sed -e 's/.*\[\(.*\)\].*/\1/' | tr -s "," " " | sed 's/\"/ /g' | awk '{for (i=1; i <= 100; i++) {printf "%s ", $i}}')
    #
    # if the list of inidentids is not enpty
    if [ $incidentids != $NO_IDS ] ; then
        #
        # Get the last incident in incidentIDs
        lastincident=$(echo $incidentidslist | awk '{print $NF}')
        #
        # Get the last run time
        lastrun=$(curl -k -s -u "${user}":"${passwd}" "https://${DLP_HOST}:${DLP_PORT}/rest/dlp/incidents/$lastincident?incidentNature=1" | sed -e 's/^.*"occurred_UTC":"\([^"]*\)".*$/\1/')
        #
        # Since it returns a date tranform it into milliseconds
        # add 1 second so next run gets new incidentIDs
        newlastrunmillisec=$(($(date -d"$lastrun" +%s)*1000+1000))
          echo "$newlastrunmillisec" > $LOGSTASH_DATA_DIR/$LASTINCIDENTTIME

        #
        # Loop through incidentIDs and go get the inicident information
        for incident in $incidentidslist; do
            results+=("$(curl -k -s -u "${user}":"${passwd}" "https://${DLP_HOST}:${DLP_PORT}/rest/dlp/incidents/$incident?incidentNature=1")")

        done
    #
    # Loop through results and let echo add a newline character needed
    # for each HBSS DLP Incident
    for i in "${results[@]}"; do
      echo "$i"
    done
    exit

    else
    #
    # There are no incidentIds return nothing elastic will skip
    echo ""
    exit
    fi
