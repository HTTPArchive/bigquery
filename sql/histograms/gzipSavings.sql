#standardSQL
SELECT
  *,
  SUM(pdf) OVER (PARTITION BY client ORDER BY bin) AS cdf
FROM (
  SELECT
    *,
    volume / SUM(volume) OVER (PARTITION BY client) AS pdf
  FROM (
    SELECT
      _TABLE_SUFFIX AS client,
      COUNT(0) AS volume,
      CAST(FLOOR(CAST(JSON_EXTRACT(payload, "$._gzip_savings") AS FLOAT64) / (1024 * 2)) * 2 AS INT64) AS bin
    FROM
      `httparchive.pages.${YYYY_MM_DD}_*`
    GROUP BY
      bin,
      client
    HAVING
      bin IS NOT NULL) )
ORDER BY
  bin,
  client
