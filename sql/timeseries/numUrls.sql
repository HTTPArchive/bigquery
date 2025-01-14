#standardSQL
SELECT
  FORMAT_TIMESTAMP('%Y_%m_%d', date) AS date,
  UNIX_DATE(date) * 1000 * 60 * 60 * 24 AS timestamp,
  client,
  COUNT(0) AS urls
FROM
  `httparchive.crawl.pages`
WHERE
  date >= '2010-11-15' AND
  is_root_page
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client
