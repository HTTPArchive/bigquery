#standardSQL
SELECT
  SUBSTR(_TABLE_SUFFIX, 0, 10) AS date,
  UNIX_DATE(CAST(REPLACE(SUBSTR(_TABLE_SUFFIX, 0, 10), '_', '-') AS DATE)) * 1000 * 60 * 60 * 24 AS timestamp,
  IF(ENDS_WITH(_TABLE_SUFFIX, 'desktop'), 'desktop', 'mobile') AS client,
  ROUND(APPROX_QUANTILES(CAST(JSON_EXTRACT(payload, "$._image_savings") AS FLOAT64), 1001)[OFFSET(101)] / 1024, 2) AS p10,
  ROUND(APPROX_QUANTILES(CAST(JSON_EXTRACT(payload, "$._image_savings") AS FLOAT64), 1001)[OFFSET(251)] / 1024, 2) AS p25,
  ROUND(APPROX_QUANTILES(CAST(JSON_EXTRACT(payload, "$._image_savings") AS FLOAT64), 1001)[OFFSET(501)] / 1024, 2) AS p50,
  ROUND(APPROX_QUANTILES(CAST(JSON_EXTRACT(payload, "$._image_savings") AS FLOAT64), 1001)[OFFSET(751)] / 1024, 2) AS p75,
  ROUND(APPROX_QUANTILES(CAST(JSON_EXTRACT(payload, "$._image_savings") AS FLOAT64), 1001)[OFFSET(901)] / 1024, 2) AS p90
FROM
  `httparchive.pages.*`
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client
