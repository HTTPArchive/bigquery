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

cd $HOME/code/dataflow/java
BASE=`pwd`

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

mvn compile exec:java -Dexec.mainClass=com.httparchive.dataflow.BigQueryImport \
  -Dexec.args="--project=httparchive --stagingLocation=gs://httparchive/dataflow/staging \
               --runner=BlockingDataflowPipelineRunner --input=${bucket} \
               --workerMachineType=n1-highmem-4"


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
