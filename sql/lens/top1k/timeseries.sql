SELECT
  page,
  client,
  date,
  is_root_page
FROM
  `httparchive.crawl.pages`
WHERE
  date >= '2021-05-01' AND
  is_root_page AND
  rank <= 1000
GROUP BY
  1,
  2,
  3,
  4
