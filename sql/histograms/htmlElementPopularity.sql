#standardSQL
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
  `httparchive.all.pages`
JOIN
  (
    SELECT
      date,
      client,
      COUNT(DISTINCT root_page) AS total
    FROM
      `httparchive.all.pages`
    WHERE
      date = PARSE_DATE('%Y_%m_%d', '${YYYY_MM_DD}') AND
      rank = 1000
    GROUP BY
      date,
      client
  )
USING (date, client),
  UNNEST(getElements(JSON_EXTRACT(custom_metrics, '$.element_count'))) AS element
WHERE
  date = PARSE_DATE('%Y_%m_%d', '${YYYY_MM_DD}')
GROUP BY
  client,
  total,
  element
HAVING
  COUNT(DISTINCT root_page) >= 10
ORDER BY
  pages / total DESC,
  client
