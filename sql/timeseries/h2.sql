#standardSQL
SELECT
  SUBSTR(_TABLE_SUFFIX, 0, 10) AS date,
  UNIX_DATE(CAST(REPLACE(SUBSTR(_TABLE_SUFFIX, 0, 10), '_', '-') AS DATE)) * 1000 * 60 * 60 * 24 AS timestamp,
  IF(ENDS_WITH(_TABLE_SUFFIX, 'desktop'), 'desktop', 'mobile') AS client,
  ROUND(SUM(IF(protocol = 'HTTP/2', 1, 0)) * 100 / COUNT(0), 2) AS percent
FROM
  (
    SELECT
      page AS url,
      JSON_EXTRACT_SCALAR(payload, '$._protocol') AS protocol,
      _TABLE_SUFFIX AS _TABLE_SUFFIX
    FROM
      `httparchive.requests.*`
    WHERE
      1=1 /* Dummy join to allow date joins on this subquery for cost/time savings */
  )
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client
