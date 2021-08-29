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
#   -l: Optional name of the report lens to generate, eg "top10k".
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
VERBOSE=0

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
		v)
			VERBOSE=1
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

		if [[ -z $query ]]; then
			echo "Nothing to do"
			continue;
		fi

		# Extract the metric name from the file path.
		# For example, `sql/histograms/foo.sql` will produce `foo`.
		metric=$(echo $(basename $query) | cut -d"." -f1)

		gs_url="gs://httparchive/reports/$gs_lens_dir$YYYY_MM_DD/${metric}.json"
		gsutil ls $gs_url &> /dev/null
		if [ $? -eq 0 ] && [ $FORCE -eq 0 ]; then
			# The file already exists, so skip the query.
			echo -e "Skipping $metric histogram as already exists"
			continue
		fi

		echo -e "Generating $metric histogram"

		# Replace the date template in the query.
		if [[ $LENS != "" ]]; then
			lens_join="JOIN ($(cat sql/lens/$LENS/histograms.sql | tr '\n' ' ')) USING (url, _TABLE_SUFFIX)"
			if [[ $metric == crux* ]]; then
				if [[ -f sql/lens/$LENS/crux_histograms.sql ]]; then
					echo "Using alternative crux lens join"
					lens_join="$(cat sql/lens/$LENS/crux_histograms.sql | sed -e "s/--noqa: disable=PRS//g" | tr '\n' ' ')"
				else
					echo "CrUX queries do not support histograms for this lens so skipping"
					continue
				fi

				query=$(sed -e "s/\(\`chrome-ux-report[^\`]*\`\)/\1 $lens_join/" $query \
					| sed -e "s/\${YYYY_MM_DD}/$YYYY_MM_DD/g" \
					| sed -e "s/\${YYYYMM}/$YYYYMM/g")
			else
				query=$(sed -e "s/\(\`[^\`]*\`)*\)/\1 $lens_join/" $query \
					| sed -e "s/\${YYYY_MM_DD}/$YYYY_MM_DD/g" \
					| sed -e "s/\${YYYYMM}/$YYYYMM/g")
			fi
		else
			query=$(sed -e "s/\${YYYY_MM_DD}/$YYYY_MM_DD/" $query \
				| sed -e "s/\${YYYYMM}/$YYYYMM/")
		fi

		if [ ${VERBOSE} -eq 1 ]; then
			echo "Running this query:"
			echo $query
		fi

		# Run the histogram query on BigQuery.
		START_TIME=$SECONDS
		result=$(cat $QUERY | $BQ_CMD)

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

		if [[ -z $query ]]; then
			echo "Nothing to do"
			continue;
		fi

		# Extract the metric name from the file path.
		metric=$(echo $(basename $query) | cut -d"." -f1)

		date_join=""
		max_date=""
		current_contents=""
		gs_url="gs://httparchive/reports/$gs_lens_dir${metric}.json"
		gsutil ls $gs_url &> /dev/null
		if [ $? -eq 0 ]; then
			# The file already exists, so check max date
			current_contents=$(gsutil cat $gs_url)
			max_date=$(echo $current_contents | jq -r '[ .[] | .date ] | max')
			if [[ $FORCE -eq 0 && -n "${max_date}" ]]; then

				# Only run if new dates
				if [[ -z "${YYYY_MM_DD}" || "${max_date}" < "${YYYY_MM_DD}" ]]; then
					if [[ $(grep "httparchive.blink_features.usage" $query) && $LENS == "" ]]; then # blink needs a special join, different for lenses
						date_join="yyyymmdd > REPLACE(\"$max_date\",\"_\",\"\")"
						if [[ -n "$YYYY_MM_DD" ]]; then
							# If a date is given, then only run up until then (in case next month is mid-run as don't wanna get just desktop data)
							date_join="${date_join} AND yyyymmdd <= REPLACE(\"$YYYY_MM_DD\",\"_\",\"\")"
						fi
					elif [[ $(grep "httparchive.blink_features.usage" $query) && $LENS != "" ]]; then # blink needs a special join, different for lenses
						date_join="yyyymmdd > CAST(REPLACE(\"$max_date\",\"_\",\"-\") AS DATE)"
						if [[ -n "$YYYY_MM_DD" ]]; then
							# If a date is given, then only run up until then (in case next month is mid run as don't wanna get just desktop data)
							date_join="${date_join} AND yyyymmdd <= CAST(REPLACE(\"$YYYY_MM_DD\",\"_\",\"-\") AS DATE)"
						fi
					elif [[ $metric != crux* ]]; then # CrUX is quick and join is more compilicated so just do a full run of that
						date_join="SUBSTR(_TABLE_SUFFIX, 0, 10) > \"$max_date\""
						if [[ -n "$YYYY_MM_DD" ]]; then
							# If a date is given, then only run up until then (in case next month is mid run as don't wanna get just desktop data)
							date_join="${date_join} AND SUBSTR(_TABLE_SUFFIX, 0, 10) <= \"$YYYY_MM_DD\""
						fi
					fi

					echo -e "Generating $metric timeseries in incremental mode from ${max_date} to ${YYYY_MM_DD}"

				else
					echo -e "Skipping $metric timeseries as ${YYYY_MM_DD} already exists in the data. Run in force mode (-f) if you want to rerun."
					continue
				fi

			elif [[ -n "$YYYY_MM_DD" ]]; then
				# Even if doing a force run we only wanna run up until date given in case next month is mid-run as don't wanna get just desktop data
				if [[ $(grep "httparchive.blink_features.usage" $query) && $LENS == "" ]]; then # blink needs a special join, different for lenses
					date_join="yyyymmdd <= REPLACE(\"$YYYY_MM_DD\",\"_\",\"\")"
				elif [[ $(grep "httparchive.blink_features.usage" $query) && $LENS != "" ]]; then # blink needs a special join, different for lenses
					date_join="yyyymmdd <= CAST(REPLACE(\"$YYYY_MM_DD\",\"_\",\"-\") AS DATE)"
				elif [[ $metric != crux* ]]; then # CrUX is quick and join is more compilicated so just do a full run of that
					# If a date is given, then only run up until then (in case next month is mid run as don't wanna get just desktop data)
					date_join="SUBSTR(_TABLE_SUFFIX, 0, 10) <= \"$YYYY_MM_DD\""
				fi

				echo -e "Force Mode=${FORCE}. Generating $metric timeseries from start until ${YYYY_MM_DD}."
			fi
		elif [[ -n "$YYYY_MM_DD" ]]; then
			# Even if the file doesn't exist we only wanna run up until date given in case next month is mid-run as don't wanna get just desktop data
			if [[ $(grep "httparchive.blink_features.usage" $query) && $LENS == "" ]]; then # blink needs a special join, different for lenses
				date_join="yyyymmdd <= REPLACE(\"$YYYY_MM_DD\",\"_\",\"\")"
			elif [[ $(grep "httparchive.blink_features.usage" $query) && $LENS != "" ]]; then # blink needs a special join, different for lenses
				date_join="yyyymmdd <= CAST(REPLACE(\"$YYYY_MM_DD\",\"_\",\"-\") AS DATE)"
			elif [[ $metric != crux* ]]; then # CrUX is quick and join is more compilicated so just do a full run of that
				date_join="SUBSTR(_TABLE_SUFFIX, 0, 10) <= \"$YYYY_MM_DD\""
			fi

			echo -e "Timeseries does not exist. Generating $metric timeseries from start until ${YYYY_MM_DD}"

		else
			echo -e "Timeseries does not exist. Generating $metric timeseries from start"
		fi

		if [[ $LENS != "" ]]; then

			if [[ $(grep "httparchive.blink_features.usage" $query) ]]; then
				# blink_features.usage need to be replace by blink_features.features for lenses
				if [[ -f sql/lens/$LENS/blink_timeseries.sql ]]; then
					echo "Using alternative blink_timeseries lens join"
					lens_join="$(cat sql/lens/$LENS/blink_timeseries.sql | tr '\n' ' ')"

					# For blink features for lenses we have a BLINK_DATE_JOIN variable to replace
					if [[ -z "${date_join}" ]]; then
						query=$(sed -e "s/\`httparchive.blink_features.usage\`/($lens_join)/" $query \
						| sed -e "s/ {{ BLINK_DATE_JOIN }}//g")
					else
						query=$( sed -e "s/\`httparchive.blink_features.usage\`/($lens_join)/" $query \
							| sed -e "s/{{ BLINK_DATE_JOIN }}/AND $date_join/g")
					fi
				else
					echo "blink_features.usage queries not supported for this lens so skipping lens"
					continue
				fi
			else

				lens_join="JOIN ($(cat sql/lens/$LENS/timeseries.sql | tr '\n' ' ')) USING (url, _TABLE_SUFFIX)"
				if [[ $metric == crux* ]]; then
					echo "CrUX query so using alternative lens join"
					lens_join="JOIN ($(cat sql/lens/$LENS/timeseries.sql | tr '\n' ' ')) ON (origin || '\/' = url AND REGEXP_REPLACE(CAST(yyyymm AS STRING), '(\\\\\\\\d{4})(\\\\\\\\d{2})', '\\\\\\\\1_\\\\\\\\2_01') || '_' || IF(device = 'phone', 'mobile', device) = _TABLE_SUFFIX)"
				fi

				if [[ -n "${date_join}" ]]; then
					if [[ $(grep -i "WHERE" $query) ]]; then
						# If WHERE clause already exists then add to it, before GROUP BY
						query=$(sed -e "s/\(WHERE\)/\1 $date_join AND/" $query \
							| sed -e "s/\(\`[^\`]*\`)*\)/\1 $lens_join/")
					else
						# If WHERE clause doesn't exists then add it, before GROUP BY
						query=$(sed -e "s/\(GROUP BY\)/WHERE $date_join \1/" $query \
							| sed -e "s/\(\`[^\`]*\`)*\)/\1 $lens_join/")
					fi
				else
					query=$(sed -e "s/\(\`[^\`]*\`)*\)/\1 $lens_join/" $query)
				fi
			fi

		else
			if [[ -n "${date_join}" ]]; then
				if [[ $(grep -i "WHERE" $query) ]]; then
					# If WHERE clause already exists then add to it, before GROUP BY
					query=$(sed -e "s/\(WHERE\)/\1 $date_join AND /" $query)
				else
					# If WHERE clause doesn't exists then add it, before GROUP BY
					query=$(sed -e "s/\(GROUP BY\)/WHERE $date_join \1/" $query)
				fi
			fi
		fi

		if [ ${VERBOSE} -eq 1 ]; then
			echo "Running this query:"
			echo $query
		fi

		# Run the timeseries query on BigQuery.
		START_TIME=$SECONDS
		result=$(cat $QUERY | $BQ_CMD)

		# Make sure the query succeeded.
		if [ $? -eq 0 ]; then
			ELAPSED_TIME=$(($SECONDS - $START_TIME))
			if [[ $LENS != "" ]]; then
				echo "$metric for $LENS took $ELAPSED_TIME seconds"
			else
				echo "$metric took $ELAPSED_TIME seconds"
			fi

			# If it's a partial run, then combine with the current results.
			if [[ $FORCE -eq 0 && -n "${current_contents}" ]]; then
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
