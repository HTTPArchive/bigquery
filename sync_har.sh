#!/bin/bash
#
# Usage:
#
#   ./sync_har.sh [chrome,android] [YYYY-MM-DD]
#
# Examples:
#
#   ./sync_har.sh chrome
#   ./sync_har.sh chrome 2019-01-01
#   ./sync_har.sh android 2018-12-15
#

cd $HOME/code/dataflow/python

if [ -n "$2" ]; then
  day=$(date -d $2 +%d)
  MM=$(date -d $2 +%m)
  month=$(date -d $2 +%b)
  year=$(date -d $2 +%Y)
else
  day=$(date +%d)
  MM=$(date +%m)
  month=$(date +%b)
  year=$(date +%Y)
fi

# All crawls begin on the first of the month.
import_date=$(date +"${month}_1_${year}")
table="${year}_${MM}_01"

if [ -n "$1" ]; then
  archive=$1
  if [[ $1 == *chrome* ]]; then
    client="desktop"
    bucket="chrome-${import_date}"
  else
    client="mobile"
    bucket="android-${import_date}"
  fi
  echo "Processing $bucket, client: $client"

else
  echo "Must provide import type (e.g. chrome), and optional date:"
  echo "\t script.sh chrome 2016-01-15"
  exit
fi

if bq show "httparchive:pages.${table}_${client}"; then
  echo "Table already exists in BigQuery, exiting"
  exit 1
else
  echo "Table does not exist in BigQuery, checking gs://..."
fi

if ! gsutil stat "gs://httparchive/${bucket}/done"; then
  echo "Bucket does not exist or has not finished importing"
  exit 1
else
  echo "Bucket exists, initiating DataFlow import..."
fi

export GOOGLE_APPLICATION_CREDENTIALS="./credentials/auth.json"

if [ ! -f $GOOGLE_APPLICATION_CREDENTIALS ]; then
  echo "ERROR: ${GOOGLE_APPLICATION_CREDENTIALS} does not exist. See README for more info."
  exit 1
fi

source env/bin/activate

python bigquery_import.py \
  --runner=DataflowRunner \
  --project=httparchive \
  --temp_location=gs://httparchive/dataflow/temp \
  --staging_location=gs://httparchive/dataflow/staging \
  --region=us-west1 \
  --machine_type=n1-standard-32 \
  --input="${bucket}" \
  --worker_disk_type=compute.googleapis.com/projects//zones//diskTypes/pd-ssd \
  --experiment=use_beam_bq_sink

deactivate

echo -e "Attempting to generate reports..."
cd $HOME/code

gsutil -q stat gs://httparchive/reports/$table/*
if [ $? -eq 1 ]; then
  . sql/generate_reports.sh -fth $table
  ls -1 sql/lens | xargs -I lens sql/generate_reports.sh -fth $table -l lens
else
  echo -e "Reports for ${table} already exist, skipping."
fi

echo "Done"
