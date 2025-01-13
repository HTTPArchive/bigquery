SELECT
  url,
  client
FROM
  `httparchive.crawl.pages`
WHERE
  date = '${YYYY-MM-DD}' AND
  is_root_page AND
  rank <= 1000
GROUP BY
  1,
  2
