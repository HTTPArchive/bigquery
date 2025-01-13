#standardSQL
SELECT
  FORMAT_TIMESTAMP('%Y_%m_%d', date) AS date,
  UNIX_DATE(date) * 1000 * 60 * 60 * 24 AS timestamp,
  client,
  ROUND(SUM(IF(LAX_STRING(r.summary.respHttpVersion) = 'HTTP/2', 1, 0)) * 100 / COUNT(0), 2) AS percent
FROM
  `httparchive.crawl.requests` r
INNER JOIN
  `httparchive.crawl.pages`
USING (date, client, is_root_page, rank)
WHERE
  is_root_page AND
  date >= '2016-07-15'
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client
