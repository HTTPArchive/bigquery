SELECT
  url,
  _TABLE_SUFFIX AS _TABLE_SUFFIX
FROM
  `httparchive.summary_pages.${YYYY_MM_DD}_*`
WHERE
  rank <= 1000
GROUP BY
  1,
  2
