#!/bin/bash
#
# Updates the JSON reports on Google Storage with the latest BigQuery data.
#
# Usage:
#
#   $ sql/generateReports.sh -t -h YYYY_MM_DD
#
# Flags:
#
#   -t: Whether to generate timeseries.
#
#   -h: Whether to generate histograms. Must be accompanied by the date to query.
#
#   -f: Whether to force querying and updating even if the data exists.
#
#   -l: Optional name of the report lens to generate, eg "wordpress".
#

set -o pipefail

BQ_CMD="bq --format prettyjson --project_id httparchive query --max_rows 1000000"
FORCE=0
GENERATE_HISTOGRAM=0
GENERATE_TIMESERIES=0
LENS=""

# Read the flags.
while getopts ":fth:l:" opt; do
	case "${opt}" in
		h)
			GENERATE_HISTOGRAM=1
			YYYY_MM_DD=${OPTARG}
			dateParts=(`echo ${OPTARG} | tr "_" "\\n"`)
			YYYYMM=${dateParts[0]}${dateParts[1]}
			;;
		t)
			GENERATE_TIMESERIES=1
			;;
		f)
			FORCE=1
			;;
		l)
			LENS=${OPTARG}
			;;
	esac
done

# Exit early if there's nothing to do.
if [ $GENERATE_HISTOGRAM -eq 0 -a $GENERATE_TIMESERIES -eq 0 ]; then
	echo -e "You must provide one or both -t or -h flags." >&2
	echo -e "For example: sql/generateReports.sh -t -h 2017_08_01" >&2
	exit 1
fi

# Check if all tables for the given date are available in BigQuery.
# Tables representing desktop/mobile and HAR/CSV data sources must exist.
(bq show "httparchive:pages.${YYYY_MM_DD}_desktop" && \
	bq show "httparchive:pages.${YYYY_MM_DD}_mobile" && \
	bq show "httparchive:summary_pages.${YYYY_MM_DD}_desktop" && \
	bq show "httparchive:summary_pages.${YYYY_MM_DD}_mobile") &> /dev/null
if [ $GENERATE_HISTOGRAM -ne 0 -a $? -ne 0 ]; then
	echo -e "The BigQuery tables for $YYYY_MM_DD are not available." >&2
	exit 1
fi

gs_lens_dir=""
if [[ $LENS != "" ]]; then
	if [ ! -f "sql/lens/$LENS/histograms.sql" ] || [ ! -f "sql/lens/$LENS/timeseries.sql" ]; then
		echo -e "Lens histogram/timeseries files not found in sql/lens/$LENS."
		exit 1
	fi
	echo -e "Generating reports for $LENS"
	gs_lens_dir="$LENS/"
fi

if [ $GENERATE_HISTOGRAM -eq 0 ]; then
	echo -e "Skipping histograms"
else
	echo -e "Generating histograms for date $YYYY_MM_DD"

	# Run all histogram queries.
	for query in sql/histograms/*.sql; do
		# Extract the metric name from the file path.
		# For example, `sql/histograms/foo.sql` will produce `foo`.
		metric=$(echo $(basename $query) | cut -d"." -f1)

		gs_url="gs://httparchive/reports/$gs_lens_dir$YYYY_MM_DD/${metric}.json"
		gsutil ls $gs_url &> /dev/null
		if [ $? -eq 0 ] && [ $FORCE -eq 0 ]; then
			# The file already exists, so skip the query.
			echo -e "Skipping $metric histogram"
			continue
		fi

		echo -e "Generating $metric histogram"

		# Replace the date template in the query.
		# Run the query on BigQuery.
		if [[ $LENS != "" ]]; then
			lens_join="JOIN ($(cat sql/lens/$LENS/histograms.sql | tr '\n' ' ')) USING (url, _TABLE_SUFFIX)"
			result=$(sed -e "s/\(\`[^\`]*\`)*\)/\1 $lens_join/" $query \
				| sed -e "s/\${YYYY_MM_DD}/$YYYY_MM_DD/g" \
				| sed  -e "s/\${YYYYMM}/$YYYYMM/g" \
				| $BQ_CMD)
		else
			result=$(sed -e "s/\${YYYY_MM_DD}/$YYYY_MM_DD/" $query \
				| sed  -e "s/\${YYYYMM}/$YYYYMM/" \
				| $BQ_CMD)
		fi
		# Make sure the query succeeded.
		if [ $? -eq 0 ]; then
			# Upload the response to Google Storage.
			echo $result \
				| gsutil  -h "Content-Type:application/json" cp - $gs_url
		else
			echo $result >&2
		fi
	done
fi

if [ $GENERATE_TIMESERIES -eq 0 ]; then
	echo -e "Skipping timeseries"
else
	echo -e "Generating timeseries"

	# Run all timeseries queries.
	for query in sql/timeseries/*.sql; do
		# Extract the metric name from the file path.
		metric=$(echo $(basename $query) | cut -d"." -f1)

		gs_url="gs://httparchive/reports/$gs_lens_dir${metric}.json"
		gsutil ls $gs_url &> /dev/null
		if [ $? -eq 0 ] && [ $FORCE -eq 0 ]; then
			# The file already exists, so skip the query.
			echo -e "Skipping $metric timeseries"
			continue
		fi

		echo -e "Generating $metric timeseries"

		# Run the query on BigQuery.
		if [[ $LENS != "" ]]; then
			lens_join="JOIN ($(cat sql/lens/$LENS/timeseries.sql | tr '\n' ' ')) USING (url, _TABLE_SUFFIX)"
			result=$(sed -e "s/\(\`[^\`]*\`)*\)/\1 $lens_join/" $query \
				| $BQ_CMD)
		else
			result=$(cat $query \
				| $BQ_CMD)
		fi
		# Make sure the query succeeded.
		if [ $? -eq 0 ]; then
			# Upload the response to Google Storage.
			echo $result \
				| gsutil  -h "Content-Type:application/json" cp - $gs_url
		else
			echo $result >&2
		fi
	done
fi

echo -e "Done"
