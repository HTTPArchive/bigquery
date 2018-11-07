#!/bin/bash
#
# Initializes reports for a newly added metric.
#
# Example usage:
#
#   sql/new_metric.sh histograms bootupJs lighthouse
#
# Where the first argument is the chart type,
# the second argument is the metric name,
# and the third argument is the BQ dataset.

set -eo pipefail

VIZ=$1
METRIC=$2
DATASET=$3

if [ -z "$VIZ" ]; then
  echo "Chart type argument required." >&2
  echo "Example usage: sql/new_metric.sh histograms bootupJs lighthouse" >&2
  exit 1
fi

if [ -z "$METRIC" ]; then
  echo "Metric argument required." >&2
  echo "Example usage: sql/new_metric.sh histograms bootupJs lighthouse" >&2
  exit 1
fi

if [ -z "$DATASET" ]; then
  echo "Dataset argument required." >&2
  echo "Example usage: sql/new_metric.sh histograms bootupJs lighthouse" >&2
  exit 1
fi

if [ "$VIZ" == "histograms" ]; then
  cmd='sql/get_bigquery_dates.sh "$DATASET" "" | xargs -I date sql/generate_report.sh -d date/"$METRIC".json'
fi
if [ "$VIZ" == "timeseries" ]; then
  cmd='sql/generate_report.sh -d "$METRIC".json'
fi

eval $cmd

lenses=$(ls -1 sql/lens)
for lens in $lenses; do
  cmd+=" -l $lens"
  eval $cmd
done
