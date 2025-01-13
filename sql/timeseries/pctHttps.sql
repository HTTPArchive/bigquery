#standardSQL
SELECT
  FORMAT_TIMESTAMP('%Y_%m_%d', date) AS date,
  UNIX_DATE(date) * 1000 * 60 * 60 * 24 AS timestamp,
  client,
  ROUND(SUM(IF(STARTS_WITH(request, 'https'), 1, 0)) * 100 / COUNT(0), 2) AS percent
FROM
  (SELECT url AS request, page AS url, client, date FROM `httparchive.crawl.requests` WHERE is_root_page AND date >= '2016-01-01')
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client
