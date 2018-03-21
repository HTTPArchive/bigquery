#!/bin/bash

if [ -n "$1" ]; then
  table=$1
else
  echo "ERROR: Expected YYYY_MM_DD argument."
  exit 1
fi

# Check if all tables for the given crawl are available in BigQuery.
# Tables representing desktop/mobile and HAR/CSV data sources must exist.
(bq show "httparchive:pages.${table}_desktop" && \
	bq show "httparchive:pages.${table}_mobile" && \
	bq show "httparchive:summary_pages.${table}_desktop" && \
	bq show "httparchive:summary_pages.${table}_mobile") &> /dev/null
if [ $? -eq 0 ]; then
  echo "Great! It looks like all $table tables exist in BigQuery."
  echo "Starting the report generation now..."
  . sql/generateReports.sh -fth $table
else
  echo "Not all (summary_)pages.$table tables exist for dekstop/mobile."
  echo "Aborting report generation."
fi
