SELECT
  page,
  client
FROM
  `httparchive.crawl.pages`
WHERE
  date = '${YYYY-MM-DD}' AND
  is_root_page AND
  rank <= 10000
GROUP BY
  1,
  2
