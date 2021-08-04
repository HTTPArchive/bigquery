#standardSQL
CREATE TEMPORARY FUNCTION getElements(payload STRING)
RETURNS ARRAY<STRING> LANGUAGE js AS '''
try {
  var $ = JSON.parse(payload);
  var elements = JSON.parse($._element_count);
  if (Array.isArray(elements) || typeof elements != 'object') return [];
  return Object.keys(elements);
} catch (e) {
  return [];
}
''';

 SELECT
  _TABLE_SUFFIX AS client,
  element,
  COUNT(DISTINCT url) AS pages,
  total,
  COUNT(DISTINCT url) / total AS pct,
  ARRAY_TO_STRING(ARRAY_AGG(DISTINCT url LIMIT 5), ' ') AS sample_urls
FROM
  `httparchive.pages.${YYYY_MM_DD}_*`
JOIN
  (SELECT _TABLE_SUFFIX, COUNT(0) AS total FROM `httparchive.pages.${YYYY_MM_DD}_*` GROUP BY _TABLE_SUFFIX)
USING (_TABLE_SUFFIX),
  UNNEST(getElements(payload)) AS element
GROUP BY
  client,
  total,
  element
HAVING
  COUNT(DISTINCT url) >= 10
ORDER BY
  pages / total DESC,
  client
