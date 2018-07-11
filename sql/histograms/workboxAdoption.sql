#standardSQL
SELECT
  date,
  count (uses_workboxjs) AS total_uses_workbox
FROM
  `progressive_web_apps.service_workers`
WHERE
  uses_workboxjs
GROUP BY
  date
ORDER BY
  date;