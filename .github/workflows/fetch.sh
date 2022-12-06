#!/bin/bash -e

baseDestDir=./data/raw
destDir=$baseDestDir/$(date +%Y%m%d_%H%M%S)
mkdir $destDir
startParameter=0

reqNum=1
while true
do
    fetchURL="https://e-redes.opendatasoft.com/api/records/1.0/search/?dataset=outages-per-geography&q=&facet=zipcode&facet=municipality&start=$startParameter"
    oFileName=$destDir/$( printf '%09d' $reqNum ).json

    curl "$fetchURL" -o $oFileName
    curNHits=$(jq '.nhits' $oFileName)
    curRows=$(jq '.parameters.rows' $oFileName)
    curStart=$(jq '.parameters.start' $oFileName)

    startParameter=$((curStart+curRows))
    if (( $startParameter > $curNHits )); then
        break;
    fi

    sleep 0.2
    ((reqNum=reqNum+1))
done

# update latest records csv
echo "\".recordid\", \".record_timestamp\", \".fields.extractiondatetime\", \".fields.zipcode\", \".fields.municipality\"" > data/records/latest.csv
jq -r '.records[] | [.recordid, .record_timestamp, .fields.extractiondatetime, .fields.zipcode, .fields.municipality] | @csv ' $destDir/*.json >> data/records/latest.csv