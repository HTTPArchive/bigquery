SELECT
  FORMAT_TIMESTAMP('%Y_%m_%d', date) AS date,
  UNIX_DATE(date) * 1000 * 60 * 60 * 24 AS timestamp,
  client,
  APPROX_QUANTILES(FLOAT64(summary._connections), 1001)[OFFSET(101)] AS p10,
  APPROX_QUANTILES(FLOAT64(summary._connections), 1001)[OFFSET(251)] AS p25,
  APPROX_QUANTILES(FLOAT64(summary._connections), 1001)[OFFSET(501)] AS p50,
  APPROX_QUANTILES(FLOAT64(summary._connections), 1001)[OFFSET(751)] AS p75,
  APPROX_QUANTILES(FLOAT64(summary._connections), 1001)[OFFSET(901)] AS p90
FROM
  `httparchive.crawl.pages`
WHERE
  date >= '2010-11-15' AND
  is_root_page AND
  FLOAT64(summary._connections) > 0
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client
