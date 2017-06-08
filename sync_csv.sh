#!/bin/bash

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
  exit
fi

mkdir -p $DATA/processed/$archive

cd $DATA

if [ ! -f httparchive_${archive}_pages.csv.gz ]; then
  echo -e "Downloading data for $archive"
  wget -nv -N "http://httparchive.org/downloads/httparchive_${archive}_pages.csv.gz"
  if [ $? -ne 0 ]; then
    echo "Pages data for ${adate} is missing, exiting"
    exit
  fi
else
  echo -e "Pages data already downloaded for $archive, skipping."
fi

if [ ! -f httparchive_${archive}_requests.csv.gz ]; then
  wget -nv -N "http://httparchive.org/downloads/httparchive_${archive}_requests.csv.gz"
  if [ $? -ne 0 ]; then
    echo "Request data for ${adate} is missing, exiting"
    exit
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
	| split --lines=8000000 --filter='pigz - > $FILE.gz' - processed/$archive/requests_
fi

cd processed/${archive}

table=$(date --date="$(echo $adate | sed "s/_/ /g" -)" "+%Y_%m_%d")
ptable="runs.${table}_pages"
rtable="runs.${table}_requests"

echo -e "Syncing data to Google Storage"
gsutil cp -n * gs://httparchive/${archive}/

if [[ $mobile == 1 ]]; then
  ptable="${ptable}_mobile"
  rtable="${rtable}_mobile"
fi

bq show httparchive:${ptable} &> /dev/null
if [ $? -ne 0 ]; then
  echo -e "Submitting new pages import ${ptable} to BigQuery"
  bq --nosync load $ptable gs://httparchive/${archive}/pages.csv.gz $BASE/schema/pages.json
else
  echo -e "${ptable} already exists, skipping."
fi

bq show httparchive:${rtable} &> /dev/null
if [ $? -ne 0 ]; then
  echo -e "Submitting new requests import ${rtable} to BigQuery"
  bq load $rtable gs://httparchive/${archive}/requests_* $BASE/schema/requests.json
else
  echo -e "${rtable} already exists, skipping."
fi

cd $BASE
echo "Done"

