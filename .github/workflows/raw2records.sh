#!/bin/bash -e

if ! compgen -G "data/raw/*/*.json" > /dev/null; then
    echo "no files to process, exiting"
    exit 0
fi

jq -r '.records[] | [.recordid, .record_timestamp, .fields.extractiondatetime, .fields.zipcode, .fields.municipality] | @csv ' data/raw/*/*.json >> data/records/all.csv
rm -r data/raw/*/*.json