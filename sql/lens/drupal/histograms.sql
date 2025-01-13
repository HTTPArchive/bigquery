SELECT
  page,
  client
FROM
  `httparchive.crawl.pages`
WHERE
  date = '${YYYY-MM-DD}' AND
  'Drupal' IN UNNEST(technologies.technology)
GROUP BY
  1,
  2
