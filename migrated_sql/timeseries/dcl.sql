SELECT
  FORMAT_TIMESTAMP('%Y_%m_%d', date) AS date,
  UNIX_DATE(date) * 1000 * 60 * 60 * 24 AS timestamp,
  client,
  ROUND(APPROX_QUANTILES(FLOAT64(summary.onContentLoaded), 1001)[OFFSET(101)] / 1000, 2) AS p10,
  ROUND(APPROX_QUANTILES(FLOAT64(summary.onContentLoaded), 1001)[OFFSET(251)] / 1000, 2) AS p25,
  ROUND(APPROX_QUANTILES(FLOAT64(summary.onContentLoaded), 1001)[OFFSET(501)] / 1000, 2) AS p50,
  ROUND(APPROX_QUANTILES(FLOAT64(summary.onContentLoaded), 1001)[OFFSET(751)] / 1000, 2) AS p75,
  ROUND(APPROX_QUANTILES(FLOAT64(summary.onContentLoaded), 1001)[OFFSET(901)] / 1000, 2) AS p90
FROM
  `httparchive.crawl.pages`
WHERE
  date >= '2010-11-15' AND
  is_root_page AND
  FLOAT64(summary.onContentLoaded) > 0
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client
