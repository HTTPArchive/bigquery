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
      CAST(FLOOR(CAST(IFNULL(JSON_EXTRACT(report, '$.audits.interactive.numericValue'), IFNULL(JSON_EXTRACT(report, '$.audits.consistently-interactive.rawValue'), JSON_EXTRACT(report, '$.audits.interactive.rawValue'))) AS FLOAT64) / 1000) AS INT64) AS bin
    FROM
      `httparchive.lighthouse.${YYYY_MM_DD}_*`
    GROUP BY
      bin,
      client
    HAVING
      bin IS NOT NULL) )
ORDER BY
  bin,
  client
