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
      FLOOR(CAST(IFNULL(JSON_EXTRACT(report, '$.audits.bootup-time.numericValue'), JSON_EXTRACT(report, '$.audits.bootup-time.rawValue')) AS FLOAT64) / 100) / 10 AS bin
    FROM
      `httparchive.lighthouse.${YYYY_MM_DD}_*`
    GROUP BY
      bin,
      client
    HAVING
      bin IS NOT NULL
  )
)
ORDER BY
  bin,
  client
