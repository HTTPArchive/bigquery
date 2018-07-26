SELECT
  url,
  _TABLE_SUFFIX AS _TABLE_SUFFIX
FROM
  `httparchive.technologies.*`
WHERE
  app = 'WordPress'
GROUP BY
  1,
  2
