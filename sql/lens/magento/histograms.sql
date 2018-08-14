SELECT
  url,
  _TABLE_SUFFIX AS _TABLE_SUFFIX
FROM
  `httparchive.technologies.${YYYY_MM_DD}_*`
WHERE
  app = 'Magento'
GROUP BY
  1,
  2
