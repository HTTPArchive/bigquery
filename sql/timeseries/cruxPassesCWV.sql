#standardSQL
# Passes Core Web Vitals by device

CREATE TEMP FUNCTION IS_GOOD(good FLOAT64, needs_improvement FLOAT64, poor FLOAT64) RETURNS BOOL AS (
  good / (good + needs_improvement + poor) >= 0.75
);

CREATE TEMP FUNCTION IS_NON_ZERO(good FLOAT64, needs_improvement FLOAT64, poor FLOAT64) RETURNS BOOL AS (
  good + needs_improvement + poor > 0
);

SELECT
  REGEXP_REPLACE(CAST(yyyymm AS STRING), '(\\d{4})(\\d{2})', '\\1_\\2_01') AS date,
  UNIX_DATE(CAST(REGEXP_REPLACE(CAST(yyyymm AS STRING), '(\\d{4})(\\d{2})', '\\1-\\2-01') AS DATE)) * 1000 * 60 * 60 * 24 AS timestamp,
  IF(device = 'desktop', 'desktop', 'mobile') AS client,
  SAFE_DIVIDE(
    COUNT(DISTINCT IF(
      /* INP can be null and is not mandatory for CWV */
      (p75_inp IS NULL OR IS_GOOD(fast_inp, avg_inp, slow_in[)) AND
      IS_GOOD(fast_lcp, avg_lcp, slow_lcp) AND
      IS_GOOD(small_cls, medium_cls, large_cls), origin, NULL
    )),
    COUNT(DISTINCT origin)
  ) * 100 AS percent
FROM
  `chrome-ux-report.materialized.device_summary`
WHERE
  device IN ('desktop', 'phone') AND
  yyyymm > 201909 AND
  p75_lcp IS NOT NULL AND p75_cls IS NOT NULL /* Must have LCP and CLS */
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client
