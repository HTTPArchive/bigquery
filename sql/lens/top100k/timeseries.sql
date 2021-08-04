SELECT
  url,
  _TABLE_SUFFIX AS _TABLE_SUFFIX
FROM
  `httparchive.summary_pages.*`
WHERE
  rank <= 100000 AND
  _TABLE_SUFFIX >= '2021_05_01'
GROUP BY
  1,
  2
