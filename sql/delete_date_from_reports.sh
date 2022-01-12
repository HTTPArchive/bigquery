#!/bin/bash
#
# Removes a particular date JSON from timeseries reports on Google Storage.
#
# Usage:
#
#   $ sql/delete_date_from_reports.sh -d YYYY_MM_DD
#   $ sql/delete_date_from_reports.sh -d YYYY_MM_DD -l top1k
#   $ sql/delete_date_from_reports.sh -d YYYY_MM_DD -l top1k -r "*crux*"
#
# Flags:
#
#   -l: Optional name of the report lens to generate, eg "top10k".
#
#   -r: Optional name of the report files to generate, eg "*crux*".
#

set -o pipefail

LENS_ARG=""
REPORTS="*"
VERBOSE=0
NO_CHANGES=0

# Read the flags.
while getopts ":vd:l:r:" opt; do
	case "${opt}" in
		d)
			YYYY_MM_DD=${OPTARG}
			;;
		v)
			VERBOSE=1
			;;
		l)
			LENS_ARG=${OPTARG}
			;;
		n)
			NO_CHANGES=1
			;;
		r)
			REPORTS=${OPTARG}
			;;
	esac
done

if [[ "${YYYY_MM_DD}" == "" ]]; then
  echo "Usage $0 -d 2021_12_01"
  exit 1
fi

echo "${YYYY_MM_DD}"

# Run all timeseries queries.
for query in sql/timeseries/$REPORTS.sql; do

	if [[ ! -f $query ]]; then
		echo "Nothing to do"
		continue;
	fi

	# Extract the metric name from the file path.
	metric=$(echo $(basename $query) | cut -d"." -f1)

	if [[ "${LENS_ARG}" == "" ]]; then
		LENSES=("")
		echo "Deleting ${metric} report for base"
	elif [[ "${LENS_ARG}" == "ALL" ]]; then
		LENSES=("" $(ls sql/lens))
		echo "Deleting ${metric} report for base and all lenses"
	else
		LENSES=("${LENS_ARG}")
		echo "Deleting ${metric} report for one lens"
	fi

	for LENS in "${LENSES[@]}"
	do

		gs_lens_dir=""
		if [[ $LENS != "" ]]; then
			gs_lens_dir="$LENS/"
		fi

		current_contents=""
		gs_url="gs://httparchive/reports/$gs_lens_dir${metric}.json"
		gsutil ls $gs_url &> /dev/null

		if [ $? -eq 0 ]; then

			echo "Updating this query: ${metric} for LENS: ${LENS}"

			# The file exists, so remove the requested date
			current_contents=$(gsutil cat $gs_url)

			if [ ${VERBOSE} -eq 1 ]; then
				echo "Current JSON:"
				echo "${current_contents}\n"
			fi

			new_contents=$(echo "$current_contents" | jq -c --indent 1 '.[] | select(.date!=env.YYYY_MM_DD)' | tr -d '\n' | sed 's/^/[ /' | sed 's/}$/ } ]\n/' | sed 's/}{/ }, {/g')

			if [ ${VERBOSE} -eq 1 ]; then
				echo "New JSON:"
				echo "${new_contents}\n"
			fi

			# Make sure the removal succeeded.
			if [ $? -eq 0 ] && [ ${NO_CHANGES} -eq 0 ]; then

				# Upload the response to Google Storage.
				echo "Uploading new file to Google Storage"
				echo $new_contents \
					| gsutil  -h "Content-Type:application/json" cp - $gs_url
			else
				echo $new_contents >&2
			fi
		fi
	done
done

echo -e "Done"
