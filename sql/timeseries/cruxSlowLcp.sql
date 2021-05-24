#standardSQL
SELECT
  REGEXP_REPLACE(CAST(yyyymm AS STRING), '(\\d{4})(\\d{2})', '\\1_\\2_01') AS date,
  UNIX_DATE(CAST(REGEXP_REPLACE(CAST(yyyymm AS STRING), '(\\d{4})(\\d{2})', '\\1-\\2-01') AS DATE)) * 1000 * 60 * 60 * 24 AS timestamp,
  IF(device = 'desktop', 'desktop', 'mobile') AS client,
  ROUND(SUM(slow_lcp) * 100 / (SUM(fast_lcp) + SUM(avg_lcp) + SUM(slow_lcp)), 2) AS percent
FROM
  `chrome-ux-report.materialized.device_summary`
WHERE
  yyyymm >= 201909
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client