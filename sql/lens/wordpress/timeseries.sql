SELECT
  url,
  CONCAT(date, '_', client) AS _TABLE_SUFFIX
FROM
  `httparchive.wappalyzer.detected`
WHERE
  app IN (
  SELECT
    DISTINCT name
  FROM
    `httparchive.wappalyzer.apps`,
    UNNEST(implies) AS implies
  WHERE
    name = 'WordPress'
    OR implies = 'WordPress')
GROUP BY
  1,
  2
