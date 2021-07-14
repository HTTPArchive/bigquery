#!/bin/bash
#
# Usage:
#
#   ./sync_csv.sh [mobile_][Mon_D_YYYY]
#
# Examples:
#
#   ./sync_csv.sh mobile_Dec_15_2018
#   ./sync_csv.sh Jan_1_2019

DATA=$HOME/archive
BASE=`pwd`

if [ -n "$1" ]; then
  archive=$1
  if [[ $archive == *mobile* ]]; then
    mobile=1
    adate=${archive#mobile_}
  else
    mobile=0
    adate=$archive
  fi
  echo "Processing $adate, mobile: $mobile, archive: $archive"

else
  echo "Must provide date, eg. Apr_15_2013"
  exit 1
fi

mkdir -p $DATA/processed/$archive

cd $DATA

table=$(date --date="$(echo $adate | sed "s/_/ /g" -)" "+%Y_%m_%d")

if [[ $mobile == 1 ]]; then
  table="${table}_mobile"
else
  table="${table}_desktop"
fi

ptable="summary_pages.${table}"
rtable="summary_requests.${table}"

if bq show httparchive:${ptable} &> /dev/null && \
   bq show httparchive:${rtable} &> /dev/null; then
  # Tables should be deleted from BigQuery first if the intent is to overwrite them.
  echo -e "BigQuery summary tables for $table already exist, exiting"
  exit 0
fi

if [ ! -f httparchive_${archive}_pages.csv.gz ]; then
  echo -e "Downloading data for $archive"
  gsutil cp "gs://httparchive/downloads/httparchive_${archive}_pages.csv.gz" ./
  if [ $? -ne 0 ]; then
    echo "Pages data for ${adate} is missing, exiting"
    exit 1
  fi
else
  echo -e "Pages data already downloaded for $archive, skipping."
fi

if [ ! -f httparchive_${archive}_requests.csv.gz ]; then
  gsutil cp "gs://httparchive/downloads/httparchive_${archive}_requests.csv.gz" ./
  if [ $? -ne 0 ]; then
    echo "Request data for ${adate} is missing, exiting"
    exit 1
  fi
else
  echo -e "Request data already downloaded for $archive, skipping."
fi

if [ ! -f processed/${archive}/pages.csv.gz ]; then
  echo -e "Converting pages data"
  gunzip -c "httparchive_${archive}_pages.csv.gz" \
  | sed -e 's/\\N,/"",/g' -e 's/\\N$/""/g' -e's/\([^\]\)\\"/\1""/g' -e's/\([^\]\)\\"/\1""/g' -e 's/\\"","/\\\\","/g' \
  | gzip > "processed/${archive}/pages.csv.gz"
else
  echo -e "Pages data already converted, skipping."
fi

if ls processed/${archive}/requests_* &> /dev/null; then
  echo -e "Request data already converted, skipping."
else
  echo -e "Converting requests data"
  gunzip -c "httparchive_${archive}_requests.csv.gz" \
	| sed -e 's/\\N,/"",/g' -e 's/\\N$/""/g' -e 's/\\"/""/g' -e 's/\\"","/\\\\","/g' \
  | python fixcsv.py \
	| split --lines=8000000 --filter='pigz - > $FILE.gz' - processed/$archive/requests_
fi

cd processed/${archive}

echo -e "Syncing data to Google Storage"
gsutil cp -n * gs://httparchive/${archive}/

bq show httparchive:${ptable} &> /dev/null
if [ $? -ne 0 ]; then
  echo -e "Submitting new pages import ${ptable} to BigQuery"
  bq load --max_bad_records 10 --replace $ptable gs://httparchive/${archive}/pages.csv.gz $BASE/schema/pages.json
  if [ $? -ne 0 ]; then
    echo "Error loading ${ptable}, exiting"
    exit 1
  fi
else
  echo -e "${ptable} already exists, skipping."
fi

bq show httparchive:${rtable} &> /dev/null
if [ $? -ne 0 ]; then
  echo -e "Submitting new requests import ${rtable} to BigQuery"
  bq load --max_bad_records 10 --replace $rtable gs://httparchive/${archive}/requests_* $BASE/schema/requests.json
  if [ $? -ne 0 ]; then
    echo "Error loading ${rtable}, exiting"
    exit 1
  fi
else
  echo -e "${rtable} already exists, skipping."
fi


bq show httparchive:${rtable} &> /dev/null
if [ $? -eq 0 ]; then
  echo -e "Deleting CSV artifacts..."
  rm $DATA/httparchive_${archive}_*
  rm -r $DATA/processed/$archive
else
  echo "Error loading into BigQuery, exiting"
  exit 1
fi

echo -e "Attempting to generate reports..."
cd $HOME/code

gsutil -q stat gs://httparchive/reports/$table/*
if [ $? -eq 1 ]; then
  . sql/generate_reports.sh -th $table
  ls -1 sql/lens | xargs -I lens sql/generate_reports.sh -th $table -l lens
else
  echo -e "Reports for ${table} already exist, skipping."
fi

echo "Done"
