#!/bin/bash

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

if [ $day -ge 15 ]; then
  import_date=$(date +"${month}_15_${year}")
  table="${year}_${MM}_15"
else
  import_date=$(date +"${month}_1_${year}")
  table="${year}_${MM}_01"
fi

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


echo "Attempting to generate reports..."
cd $HOME/code
. sql/generate_reports.sh -fth $table

echo "Done"
