#!/usr/bin/env bash
set -euo pipefail

baseDestDir=./data/raw
destDir=$baseDestDir/$(date +%Y%m%d_%H%M%S)
mkdir -p "$destDir"
startParameter=0

reqNum=1
echo "Starting data fetch process..."

# configurable parameters
ROWS=1000                # fetch up to this many records per request (reduces total requests)
SLEEP_BETWEEN=1          # seconds between requests
MAX_RETRIES=5            # curl retry attempts per request
INITIAL_BACKOFF=2        # seconds, exponential backoff base

fetch_with_retries() {
    local url="$1"
    local out="$2"
    local attempt=1
    while true; do
        # Use --fail to treat HTTP errors as failures, --show-error to print message, --location to follow redirects
        curl --silent --show-error --fail --location "$url" -o "$out" && return 0

        rc=$?
        echo "curl failed (code $rc) for $url (attempt $attempt/$MAX_RETRIES)"

        if (( attempt >= MAX_RETRIES )); then
            echo "Exceeded max retries ($MAX_RETRIES) for $url"
            return $rc
        fi

        backoff=$(( INITIAL_BACKOFF * (2 ** (attempt - 1)) ))
        echo "Retrying in ${backoff}s..."
        sleep "$backoff"
        ((attempt++))
    done
}

while true; do
    fetchURL="https://e-redes.opendatasoft.com/api/records/1.0/search/?dataset=outages-per-geography&q=&facet=zipcode&facet=municipality&start=$startParameter&rows=$ROWS"
    oFileName=$destDir/$(printf '%09d' "$reqNum").json

    echo "Fetching data (request #$reqNum) start=$startParameter rows=$ROWS -> $oFileName"
    if ! fetch_with_retries "$fetchURL" "$oFileName"; then
        echo "Fatal: failed to fetch data after retries. Exiting."
        exit 1
    fi
    echo "Data saved to $oFileName"

    # read values; if jq fails, abort
    curNHits=$(jq '.nhits' "$oFileName")
    curRows=$(jq '.parameters.rows' "$oFileName")
    curStart=$(jq '.parameters.start' "$oFileName")

    startParameter=$((curStart + curRows))

    if (( startParameter > curNHits )); then
        echo "All records fetched successfully."
        break
    fi

    sleep "$SLEEP_BETWEEN"
    ((reqNum = reqNum + 1))
done

# update latest records csv
latestRecordsCSV=./data/records/latest.csv

echo "Re-generating $latestRecordsCSV..."
mkdir -p "$(dirname "$latestRecordsCSV")"
echo "\".recordid\",\".record_timestamp\",\".fields.extractiondatetime\",\".fields.zipcode\",\".fields.municipality\"" > "$latestRecordsCSV"
jq -r '.records[] | [.recordid, .record_timestamp, .fields.extractiondatetime, .fields.zipcode, .fields.municipality] | @csv ' $destDir/*.json >> "$latestRecordsCSV"

echo "Successfully re-generated $latestRecordsCSV"
