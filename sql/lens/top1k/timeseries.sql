SELECT
  url,
  _TABLE_SUFFIX AS _TABLE_SUFFIX
FROM
  `httparchive.summary_pages.*`
WHERE
  rank <= 1000 AND
  _TABLE_SUFFIX >= '2021_05_01' /* Ranking only introduced in May 2021 */
GROUP BY
  1,
  2
