## HTTP Archive + BigQuery data import

_Note: you don't need to import this data yourself, the BigQuery dataset is public! [Getting started](https://github.com/HTTPArchive/httparchive.org/blob/master/docs/gettingstarted_bigquery.md)._

However, if you do want your own private copy of the dataset... The following import and sync scripts will help you import the [HTTP Archive dataset](http://httparchive.org/downloads.php) into BigQuery and keep it up to date.

```bash
$> sh sync.sh Jun_15_2013
$> sh sync.sh mobile_Jun_15_2013
```

That's all there is to it. The sync script handles all the necessary processing:

* Archives are fetched from archive.org (and cached locally)
* Archived CSV is transformed to BigQuery compatible escaping
  * You will need +pigz+ installed for parallel compression
* Request files are split into <1GB compressed CSV's
* Resulting pages and request data is synced to a Google Storage bucket
* BigQuery import is kicked off for each of compressed archives on Google Storage

After the upload is complete, a copy of the latest tables can be made with:

```bash
$> bq.py cp runs.2013_06_15_pages runs.latest_pages
$> bq.py cp runs.2013_06_15_pages_mobile runs.latest_pages_mobile
$> bq.py cp runs.2013_06_15_requests runs.latest_requests
$> bq.py cp runs.2013_06_15_requests_mobile runs.latest_requests_mobile
```

(MIT License) - Copyright (c) 2013 Ilya Grigorik
