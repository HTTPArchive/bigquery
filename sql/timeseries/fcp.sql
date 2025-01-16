#standardSQL
SELECT
  FORMAT_TIMESTAMP('%Y_%m_%d', date) AS date,
  UNIX_DATE(date) * 1000 * 60 * 60 * 24 AS timestamp,
  client,
  ROUND(APPROX_QUANTILES(FLOAT64(payload['_chromeUserTiming.firstContentfulPaint']), 1001)[OFFSET(101)] / 1024, 2) AS p10,
  ROUND(APPROX_QUANTILES(FLOAT64(payload['_chromeUserTiming.firstContentfulPaint']), 1001)[OFFSET(251)] / 1024, 2) AS p25,
  ROUND(APPROX_QUANTILES(FLOAT64(payload['_chromeUserTiming.firstContentfulPaint']), 1001)[OFFSET(501)] / 1024, 2) AS p50,
  ROUND(APPROX_QUANTILES(FLOAT64(payload['_chromeUserTiming.firstContentfulPaint']), 1001)[OFFSET(751)] / 1024, 2) AS p75,
  ROUND(APPROX_QUANTILES(FLOAT64(payload['_chromeUserTiming.firstContentfulPaint']), 1001)[OFFSET(901)] / 1024, 2) AS p90
FROM
  `httparchive.crawl.pages`
WHERE
  date >= '2016-12-15' AND
  is_root_page
GROUP BY
  date,
  timestamp,
  client
HAVING
  p50 IS NOT NULL
ORDER BY
  date DESC,
  client
