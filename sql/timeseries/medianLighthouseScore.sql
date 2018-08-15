#standardSQL
SELECT
  REGEXP_REPLACE(date, "-", "_") AS date,
  UNIX_MILLIS(TIMESTAMP(date)) AS timestamp,
  platform AS client,
  ROUND(APPROX_QUANTILES(lighthouse_pwa_score, 101)[OFFSET(11)], 2) AS p10,
  ROUND(APPROX_QUANTILES(lighthouse_pwa_score, 101)[OFFSET(26)], 2) AS p25,
  ROUND(APPROX_QUANTILES(lighthouse_pwa_score, 101)[OFFSET(51)], 2) AS p50,
  ROUND(APPROX_QUANTILES(lighthouse_pwa_score, 101)[OFFSET(76)], 2) AS p75,
  ROUND(APPROX_QUANTILES(lighthouse_pwa_score, 101)[OFFSET(91)], 2) AS p90
FROM
  `scratchspace.lighthouse_pwas`
GROUP BY
  date,
  timestamp,
  platform
ORDER BY
  date;