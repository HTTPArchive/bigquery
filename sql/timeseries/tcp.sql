#standardSQL
SELECT
  SUBSTR(_TABLE_SUFFIX, 0, 10) AS date,
  UNIX_DATE(CAST(REPLACE(SUBSTR(_TABLE_SUFFIX, 0, 10), '_', '-') AS DATE)) * 1000 * 60 * 60 * 24 AS timestamp,
  IF(ENDS_WITH(_TABLE_SUFFIX, 'desktop'), 'desktop', 'mobile') AS client,
  APPROX_QUANTILES(_connections, 1001)[OFFSET(101)] AS p10,
  APPROX_QUANTILES(_connections, 1001)[OFFSET(251)] AS p25,
  APPROX_QUANTILES(_connections, 1001)[OFFSET(501)] AS p50,
  APPROX_QUANTILES(_connections, 1001)[OFFSET(751)] AS p75,
  APPROX_QUANTILES(_connections, 1001)[OFFSET(901)] AS p90
FROM
  `httparchive.summary_pages.*`
WHERE
  _connections > 0
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client
