SELECT
  FORMAT_TIMESTAMP('%Y_%m_%d', date) AS date,
  UNIX_DATE(date) * 1000 * 60 * 60 * 24 AS timestamp,
  client,
  ROUND(COUNT(DISTINCT IF(LOWER(LAX_STRING(attr)) = 'lazy', page, NULL)) * 100 / COUNT(DISTINCT page), 2) AS percent
FROM
  `httparchive.crawl.pages`
LEFT JOIN
  UNNEST(JSON_EXTRACT_ARRAY(custom_metrics.other['img-loading-attr'])) AS attr
WHERE
  is_root_page AND
  date > '2016-01-01'
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client
