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
      CAST(JSON_EXTRACT(payload, "$['_cpu.v8.compile']") AS INT64) AS bin
    FROM
      `httparchive.requests.${YYYY_MM_DD}_*`
    GROUP BY
      bin,
      client
    HAVING
      bin IS NOT NULL AND
      bin >= 0) )
ORDER BY
  bin,
  client
