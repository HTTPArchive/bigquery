# BigQuery Pipeline

## Dataflow

TODO

## JSON Generation

After each crawl, the [generate_reports.sh](../sql/generate_reports.sh) script is run with the date of the crawl. For example:

```sh
sql/generate_reports.sh -t -h 2017_09_01
```

This will generate timeseries and histogram reports for all metrics using predefined SQL queries. The histogram queries will fill table placeholders with the crawl date provided. For example:

```sql
SELECT ... FROM `httparchive.runs.${YYYY_MM_DD}_pages* ...`
```

will become

```sql
SELECT ... FROM `httparchive.runs.2017_09_01_pages* ...`
```

After executing the histogram/timeseries queries for each metric on BigQuery, the results will be saved as JSON on Google Storage. For example, the `bytesJS` histogram would be saved to `gs://httparchive/reports/2017_09_01/bytesJS.json`. The timeseries for the same metric would be saved to `gs://httparchive/reports/bytesJS.json`.

### Running Manually

Sometimes it's necessary to manually run this process, for example if a new metric is added or specific dates need to be backfilled. The generate_reports.sh script can be run with a different configuration of flags depending on your needs. From the script's documentation:

```sh
# Flags:
#
#   -t: Whether to generate timeseries.
#
#   -h: Whether to generate histograms. Must be accompanied by the date to query.
#
#   -f: Whether to force histogram querying and updating even if the data exists.
#       Timeseries are usually appended to from last date, but this flag forces a complete rerun
```

You can omit one of the `-t` or -h` flags to focus only on histogram or timeseries generation. The `-f` flag ensures that histogram data gets overwritten. Omit this flag to skip queries for dates that already exist (much faster for batch jobs, see below).

### Getting Dates Dynamically

If you're adding a new metric, it would be a pain to run the generation script manually for each date. HTTP Archive has over 300 crawls worth of dated tables in BigQuery! The [getBigQueryDates.sh](../sql/getBigQueryDates.sh) script can be used to get all of the dates in `YYYY_MM_DD` format for a particular table type. For example, if your new metric depends on the `pages` tables of the `runs` dataset (eg `httparchive.runs.2017_09_01_pages`), you could get the dates representing all of the matiching tables by running this command:

```sh
sql/getBigQueryDates.sh runs pages
```

Or if you want to limit the results to a particular range, you can pass in upper and lower bounds:

```sh
sql/getBigQueryDates.sh runs pages 2015_01_01 2015_12_15
```

The output of this script is a newline-delimited list of dates. This format enables convenient piping of the output as input to the generate_reports.sh script. For example:

```sh
sql/getBigQueryDates.sh runs pages | \
  xargs -I date sql/generate_reports.sh -h date
```

`xargs` handles the processing of each date and calls the other script.

### Generating Specific Metrics

_TODO: document `sql/generate_report.sh`. This updates one histogram/timeseries at a time._

Running `generate_reports.sh` without the `-f` flag will result in metrics whose JSON results are already on Google Storage to skip being requeried. To regenerate results for specific metrics, the easiest thing to do may be to remove its results from Google Storage first, rather than running with the `-f` flag enabled and waiting for all other metrics to be queried and uploaded.

For example, if a change is made to the `reqTotal.sql` histogram query, then you can "invalidate" all histogram results for this query by deleting all respective JSON files from Google Storage:

```sh
gsutil rm gs://httparchive/reports/*/reqTotal.json
```

The wildcard in the YYYY_MM_DD position will instruct `gsutil` to delete all histogram results for this specific metric.

Now you can delete more metric-specific results or rerun `generate_reports.sh` without the `-f` flag and only the desired metrics will be requeried.

Note that cdn.httparchive.org may still contain the old version of the JSON file for the duration of the TTL. See below for more on invalidating the cache.

## Serving the JSON Files

The Google Storage bucket is behind an App Engine load balancer and CDN, which is aliased as [https://cdn.httparchive.org](https://cdn.httparchive.org). Accessing the JSON data follows the same pattern as the `gs://` URL. For example, the public URL for `gs://httparchive/reports/2017_09_01/bytesJS.json` is [https://cdn.httparchive.org/reports/2017_09_01/bytesJS.json](https://cdn.httparchive.org/reports/2017_09_01/bytesJS.json). Each file is configured to be served with `Content-Type: application/json` and `Cache-Control: public, max-age=3600` headers.

The cache lifetime is set to 1 hour. If the cache needs to be invalidated for a particular file, this can be done by an administrator in the App Engine dashboard.

A whitelist of origins are allowed to access the CDN. This list is maintained in [config/storage-cors.json](../config/storage-cors.json) and is configured to allow development, staging, and production servers. To save changes to this file, run:

```sh
gsutil cors set config/storage-cors.json gs://httparchive`
```

This will update the CORS settings for the Google Storage bucket.
