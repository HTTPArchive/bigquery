#standardSQL
SELECT
  REGEXP_REPLACE(date, "-", "_") AS date,
  UNIX_MILLIS(TIMESTAMP(date)) AS timestamp,
  platform AS client,
  0 AS p10,
  0 AS p25,
  COUNT(IF (message_event,
      TRUE,
      NULL)) AS p50,
  0 AS p75,
  0 AS p90
FROM
  `scratchspace.service_workers`
WHERE
  NOT uses_workboxjs
GROUP BY
  date,
  timestamp,
  platform
ORDER BY
  date;