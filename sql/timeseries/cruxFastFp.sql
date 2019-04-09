#standardSQL
SELECT
  REGEXP_REPLACE(yyyymm, '(\\d{4})(\\d{2})', '\\1_\\2_01') AS date,
  UNIX_DATE(CAST(REGEXP_REPLACE(yyyymm, '(\\d{4})(\\d{2})', '\\1-\\2-01') AS DATE)) * 1000 * 60 * 60 * 24 AS timestamp,
  IF(device = 'desktop', 'desktop', 'mobile') AS client,
  ROUND(SUM(fast_fp) * 100 / (SUM(fast_fp) + SUM(avg_fp) + SUM(slow_fp)), 2) AS percent
FROM
  `chrome-ux-report.materialized.device_summary`
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client