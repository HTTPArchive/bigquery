SELECT
  SUBSTR(page, 0, LENGTH(page) - 1) AS origin,
  IF(client = 'mobile', 'phone', client) AS device,
  date
FROM
  `httparchive.crawl.pages`
WHERE
  date >= '2010-11-15' AND
  is_root_page AND
  rank = 1000
GROUP BY
  1,
  2,
  3,
  4
