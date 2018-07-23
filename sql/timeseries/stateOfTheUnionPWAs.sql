#standardSQL
SELECT
  REGEXP_REPLACE(date, "-", "_") AS date,
  UNIX_MILLIS(TIMESTAMP(date)) AS timestamp,
  0 AS p10,
  0 AS p25,
  COUNT (DISTINCT pwa_url) AS p50,
  0 AS p75,
  0 AS p90,
  platform AS client
FROM (
  SELECT
    DISTINCT pwa_url,
    date,
    platform
  FROM
    `scratchspace.lighthouse_pwas`
  UNION ALL
  SELECT
    DISTINCT pwa_url,
    date,
    platform
  FROM
    `scratchspace.pwa_candidates`
  UNION ALL
  SELECT
    DISTINCT pwa_url,
    date,
    platform
  FROM
    `scratchspace.usecounters_pwas`)
GROUP BY
  date,
  timestamp,
  platform
ORDER BY
  timestamp;