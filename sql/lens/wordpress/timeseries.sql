SELECT
  page,
  client,
  date,
  is_root_page
FROM
  `httparchive.crawl.pages`
WHERE
  date >= '2010-11-15' AND
  is_root_page AND
  'WordPress' in UNNEST(technologies.technology)
GROUP BY
  1,
  2,
  3,
  4
