#standardSQL
SELECT
  REGEXP_REPLACE(CAST(yyyymm AS STRING), '(\\d{4})(\\d{2})', '\\1_\\2_01') AS date,
  UNIX_DATE(CAST(REGEXP_REPLACE(CAST(yyyymm AS STRING), '(\\d{4})(\\d{2})', '\\1-\\2-01') AS DATE)) * 1000 * 60 * 60 * 24 AS timestamp,
  IF(device = 'desktop', 'desktop', 'mobile') AS client,
  ROUND(SUM(larg_cls) * 100 / (SUM(small_cls) + SUM(medium_cls) + SUM(large_cls)), 2) AS percent
FROM
  `chrome-ux-report.materialized.device_summary`
WHERE
  yyyymm >= 201905
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client