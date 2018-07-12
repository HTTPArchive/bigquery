#standardSQL
SELECT
  REGEXP_REPLACE(date, "-", "_") AS date,
  count (uses_workboxjs) AS total_uses_workbox
FROM
  `scratchspace.service_workers`
WHERE
  uses_workboxjs
GROUP BY
  date
ORDER BY
  date;