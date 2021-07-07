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
#   -r: Optional name of the report files to generate, eg "*crux*".
#

set -o pipefail

BQ_CMD="bq --format prettyjson --project_id httparchive query --max_rows 1000000"
FORCE=0
GENERATE_HISTOGRAM=0
GENERATE_TIMESERIES=0
LENS=""
REPORTS="*"

# Read the flags.
while getopts ":fth:l:r:" opt; do
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
		r)
			REPORTS=${OPTARG}
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
	for query in sql/histograms/$REPORTS.sql; do
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
		START_TIME=$SECONDS
		if [[ $LENS != "" ]]; then
			lens_join="JOIN ($(cat sql/lens/$LENS/histograms.sql | tr '\n' ' ')) USING (url, _TABLE_SUFFIX)"
			if [[ $metric == crux* ]]; then
				echo "CrUX queries do not support histograms for lens's so skipping lens"
				continue
			fi
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
			ELAPSED_TIME=$(($SECONDS - $START_TIME))
			if [[ $LENS != "" ]]; then
				echo "$metric for $LENS took $ELAPSED_TIME seconds"
			else
				echo "$metric took $ELAPSED_TIME seconds"
			fi
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
	for query in sql/timeseries/$REPORTS.sql; do
		# Extract the metric name from the file path.
		metric=$(echo $(basename $query) | cut -d"." -f1)

		date_join=""
		max_date=""
		current_contents=""
		gs_url="gs://httparchive/reports/$gs_lens_dir${metric}.json"
		gsutil ls $gs_url &> /dev/null
		if [ $? -eq 0 ]; then
			# The file already exists, so check max date
			if [ $FORCE -eq 0 ]; then
				current_contents=$(gsutil cat $gs_url)
				max_date=$(echo $current_contents | jq -r '[ .[] | .date ] | max')

				if [[ "${max_date}" == "${YYYY_MM_DD}" || "${max_date}" > "${YYYY_MM_DD}" ]]; then
					echo -e "Skipping $metric timeseries"
					continue
				elif [[ $metric != crux* ]]; then # CrUX is quick and join is more compilicated so just do a full run of that
					date_join="SUBSTR(_TABLE_SUFFIX, 0, 10) > \"$max_date\""
					if [[ -n "$YYYY_MM_DD" ]]; then
						date_join="${date_join} AND SUBSTR(_TABLE_SUFFIX, 0, 10) <= \"$YYYY_MM_DD\""
					fi
				fi
			fi
		fi

		if [[ -n "${date_join}" && -n "${max_date}" ]]; then
			echo -e "Generating $metric timeseries in incremental mode from ${max_date} to ${YYYY_MM_DD}"
		else
			echo -e "Generating $metric timeseries from start"
		fi

		# Run the query on BigQuery.
		START_TIME=$SECONDS
		if [[ $LENS != "" ]]; then

			if [[ $(grep "httparchive.blink_features.usage" $query) ]]; then
				echo "blink_features.usage queries do not support lens's so skipping lens"
				continue
			fi

			lens_join="JOIN ($(cat sql/lens/$LENS/timeseries.sql | tr '\n' ' ')) USING (url, _TABLE_SUFFIX)"
			if [[ $metric == crux* ]]; then
				echo "CrUX query so using alternative lens join"
				lens_join="JOIN ($(cat sql/lens/$LENS/timeseries.sql | tr '\n' ' ')) ON (origin || '\/' = url AND REGEXP_REPLACE(CAST(yyyymm AS STRING), '(\\\\\\\\d{4})(\\\\\\\\d{2})', '\\\\\\\\1_\\\\\\\\2_01') || '_' || IF(device = 'phone', 'mobile', device) = _TABLE_SUFFIX)"
			fi

			if [[ -n "${date_join}" ]]; then
				if [[ $(grep -i "WHERE" $query) ]]; then
                    # If WHERE clause already exists then add to it
					result=$(sed -e "s/\(WHERE\)/\1 $date_join AND/" $query \
						| sed -e "s/\(\`[^\`]*\`)*\)/\1 $lens_join/" \
						| $BQ_CMD)
				else
                    # If WHERE clause doesn't exists then add it, before GROUP BY
					result=$(sed -e "s/\(GROUP BY\)/WHERE $date_join \1/" $query \
						| sed -e "s/\(\`[^\`]*\`)*\)/\1 $lens_join/" \
						| $BQ_CMD)
				fi
			else
				result=$(sed -e "s/\(\`[^\`]*\`)*\)/\1 $lens_join/" $query \
					| $BQ_CMD)
			fi

		else
			# blink_features do not support date_join so do full run for them
			if [[ -z "${date_join}" || $(grep "httparchive.blink_features.usage" $query) ]]; then
				date_join=""
				result=$(cat $query \
					| $BQ_CMD)
			elif [[ $(grep -i "WHERE" $query) ]]; then
                # If WHERE clause already exists then add to it, before GROUP BY
				result=$(sed -e "s/\(GROUP BY\)/AND $date_join \1/" $query \
					| $BQ_CMD)
			else
                # If WHERE clause doesn't exists then add it, before GROUP BY
				result=$(sed -e "s/\(GROUP BY\)/WHERE $date_join \1/" $query \
					| $BQ_CMD)
			fi
		fi

		# Make sure the query succeeded.
		if [ $? -eq 0 ]; then
			ELAPSED_TIME=$(($SECONDS - $START_TIME))
			if [[ $LENS != "" ]]; then
				echo "$metric for $LENS took $ELAPSED_TIME seconds"
			else
				echo "$metric took $ELAPSED_TIME seconds"
			fi

			# If it's a partial run, then combine with the current results.
			if [[ -n "${date_join}" ]]; then
				result=$(echo ${result} ${current_contents} | jq '.+= input')
			fi

			# Upload the response to Google Storage.
			echo $result \
				| gsutil  -h "Content-Type:application/json" cp - $gs_url
		else
			echo $result >&2
		fi
	done
fi

echo -e "Done"
