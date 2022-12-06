#!/bin/bash -e

jq -r '.records[] | [.recordid, .record_timestamp, .fields.extractiondatetime, .fields.zipcode, .fields.municipality] | @csv ' data/raw/*/*.json >> data/records/all.csv
rm -r data/raw/*/*.json