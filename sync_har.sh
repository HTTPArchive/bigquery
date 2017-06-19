#!/bin/bash

cd $HOME/code/dataflow/java
BASE=`pwd`

if [ -n "$2" ]; then
  day=$(date -d $2 +%d)
  month=$(date -d $2 +%b)
  year=$(date -d $2 +%Y)
else
  day=$(date +%d)
  month=$(date +%b)
  year=$(date +%Y)
fi

if [ $day -ge 15 ]; then
  import_date=$(date +"${month}_15_${year}")
  table="${year}_${month}_15"
else
  import_date=$(date +"${month}_1_${year}")
  table="${year}_${month}_01"
fi

if [ -n "$1" ]; then
  archive=$1
  if [[ $1 == *chrome* ]]; then
    mobile=0
    bucket="chrome-${import_date}"
    table="${table}_chrome"
  else
    mobile=1
    bucket="android-${import_date}"
    table="${table}_android"
  fi
  echo "Processing $bucket, mobile: $mobile"

else
  echo "Must provide import type (e.g. chrome), and optional date:"
  echo "\t script.sh chrome 2016-01-15"
  exit
fi

if bq show "httparchive:har.${table}_pages"; then
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
               --runner=DataflowPipelineRunner --input=${bucket} \
               --workerMachineType=n1-highmem-4"

echo "Job started, exiting."

