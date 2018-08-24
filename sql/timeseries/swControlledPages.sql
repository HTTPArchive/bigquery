#standardSQL
SELECT
  REGEXP_REPLACE(date, "-", "_") AS date,
  UNIX_MILLIS(TIMESTAMP(REGEXP_REPLACE(date, "_", "-"))) AS timestamp,
  client,
  ROUND(SUM(serviceworker_controlled_page) * 100 / COUNT(0), 2) AS percent
FROM (
  SELECT
    IF(JSON_EXTRACT(payload,
        '$._blinkFeatureFirstUsed.Features.ServiceWorkerControlledPage') IS NOT NULL,
      1,
      0) AS serviceworker_controlled_page,
    REGEXP_EXTRACT(_TABLE_SUFFIX, "\\d{4}(?:_\\d{2}){2}") AS date,
    REGEXP_EXTRACT(_TABLE_SUFFIX, ".*_(\\w+)$") AS client
  FROM
    `httparchive.pages.*`)
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date,
  client;