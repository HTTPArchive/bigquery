SELECT
  url,
  client,
  date
FROM
  `httparchive.crawl.pages`
WHERE
  date >= '2021-05-01' AND
  rank <= 1000000 AND
  is_root_page
GROUP BY
  1,
  2,
  3
