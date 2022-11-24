#!/bin/bash -e

jq -r '.records[] | [.recordid, .record_timestamp, .fields.extractiondatetime, .fields.zipcode, .fields.municipality] | @csv ' raw/*/*.json >> records/records.csv
rm -r raw/*/*.json