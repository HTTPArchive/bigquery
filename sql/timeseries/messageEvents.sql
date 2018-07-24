#standardSQL
SELECT
  REGEXP_REPLACE(date, "-", "_") AS date,
  UNIX_MILLIS(TIMESTAMP(date)) AS timestamp,
  platform AS client,
  ROUND(SUM(IF(message_event,
        1,
        0)) * 100 / COUNT(0), 2) AS percent
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