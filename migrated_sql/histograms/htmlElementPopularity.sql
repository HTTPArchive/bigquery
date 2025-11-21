CREATE TEMPORARY FUNCTION getElements(payload STRING)
RETURNS ARRAY<STRING> LANGUAGE js AS '''
try {
  var elements = JSON.parse(payload);
  if (Array.isArray(elements) || typeof elements != 'object') return [];
  return Object.keys(elements);
} catch (e) {
  return [];
}
''';

SELECT
  client,
  element,
  COUNT(DISTINCT root_page) AS pages,
  total,
  COUNT(DISTINCT root_page) / total AS pct,
  ARRAY_TO_STRING(ARRAY_AGG(DISTINCT page LIMIT 5), ' ') AS sample_urls
FROM
  `httparchive.crawl.pages`
JOIN
  (
    SELECT
      date,
      client,
      COUNT(DISTINCT root_page) AS total
    FROM
      `httparchive.crawl.pages`
    WHERE
      date = '${YYYY-MM-DD}'
    GROUP BY
      date,
      client
  )
USING (date, client),
  UNNEST(getElements(TO_JSON_STRING(custom_metrics.element_count))) AS element
WHERE
  date = '${YYYY-MM-DD}'
GROUP BY
  client,
  total,
  element
HAVING
  COUNT(DISTINCT root_page) >= 10
ORDER BY
  pages / total DESC,
  client
