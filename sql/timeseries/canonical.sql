#standardSQL
SELECT
  FORMAT_TIMESTAMP('%Y_%m_%d', date) AS date,
  UNIX_DATE(date) * 1000 * 60 * 60 * 24 AS timestamp,
  client,
  ROUND(SUM(IF(LAX_STRING(lighthouse.audits.canonical.score) IN ('true', '1'), 1, 0)) * 100 / COUNT(0), 2) AS percent
FROM
  `httparchive.crawl.pages`
WHERE
  lighthouse IS NOT NULL AND
  TO_JSON_STRING(lighthouse) != '{}' AND
  date >= '2017-06-01' AND
  is_root_page
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client
