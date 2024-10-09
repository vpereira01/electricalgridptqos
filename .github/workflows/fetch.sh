#!/bin/bash -e

baseDestDir=./data/raw
destDir=$baseDestDir/$(date +%Y%m%d_%H%M%S)
mkdir $destDir
startParameter=0

reqNum=1
echo "Starting data fetch process..."

while true; do
    fetchURL="https://e-redes.opendatasoft.com/api/records/1.0/search/?dataset=outages-per-geography&q=&facet=zipcode&facet=municipality&start=$startParameter"
    oFileName=$destDir/$(printf '%09d' $reqNum).json

    echo "Fetching data (request #$reqNum)"
    curl -s "$fetchURL" -o $oFileName
    echo "Data saved to $oFileName"

    curNHits=$(jq '.nhits' $oFileName)
    curRows=$(jq '.parameters.rows' $oFileName)
    curStart=$(jq '.parameters.start' $oFileName)

    startParameter=$((curStart + curRows))

    if (($startParameter > $curNHits)); then
        echo "All records fetched successfully."
        break
    fi

    sleep 0.2
    ((reqNum = reqNum + 1))
done

# update latest records csv
latestRecordsCSV=./data/records/latest.csv

echo "Re-generating $latestRecordsCSV..."
echo "\".recordid\",\".record_timestamp\",\".fields.extractiondatetime\",\".fields.zipcode\",\".fields.municipality\"" > $latestRecordsCSV
jq -r '.records[] | [.recordid, .record_timestamp, .fields.extractiondatetime, .fields.zipcode, .fields.municipality] | @csv ' $destDir/*.json >> $latestRecordsCSV

echo "Successfully re-generated $latestRecordsCSV"
