#standardSQL
SELECT
  REGEXP_REPLACE(date, "-", "_") AS date,
  UNIX_MILLIS(TIMESTAMP(date)) AS timestamp,
  platform AS client,
  0 as p10,
  0 as p25,
  count (uses_workboxjs) AS p50,
  0 as p75,
  0 as p90
FROM
  `scratchspace.service_workers`
WHERE
  uses_workboxjs
GROUP BY
  date,
  timestamp,
  platform
ORDER BY
  date;