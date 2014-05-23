#!/bin/bash

DATA=data
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

echo -e "Downloading data for $archive"
cd $DATA

#wget -nv -N "http://httparchive.org/downloads/httparchive_${archive}_pages.csv.gz"
#wget -nv -N "http://httparchive.org/downloads/httparchive_${archive}_requests.csv.gz"
wget -nv -N "http://www.archive.org/download/httparchive_downloads_${adate}/httparchive_${archive}_pages.csv.gz"
wget -nv -N "http://www.archive.org/download/httparchive_downloads_${adate}/httparchive_${archive}_requests.csv.gz"

if [ ! -f processed/${archive}/pages.csv.gz ]; then
  echo -e "Converting pages data"
  gunzip -c "httparchive_${archive}_pages.csv.gz" \
	| sed 's/\\N,/"",/g' \
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
	| split -l 8000000 --filter='pigz - > $FILE.gz' - processed/$archive/requests_
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
  #nosync="--nosync"
  nosync=""
else
  nosync=""
fi

echo -e "Submitting new pages import (${ptable}) to BigQuery"
$BASE/tools/bigquery-2.0.12/bq.py --nosync load $ptable \
	gs://httparchive/${archive}/pages.csv.gz $BASE/schema/pages.json

first=1
for f in `ls -r requests_*`; do
  if [[ $first == 1 ]]; then
    echo "Submitting new requests import (${rtable}) to BigQuery: $f"
    $BASE/tools/bigquery-2.0.12/bq.py $nosync load $rtable \
	gs://httparchive/${archive}/$f $BASE/schema/requests.json
    first=0
  else
    echo "Submitting append requests import (${rtable}) to BigQuery: $f"
    $BASE/tools/bigquery-2.0.12/bq.py --nosync load $rtable \
	gs://httparchive/${archive}/$f
  fi
done

cd $BASE
echo "Done"
