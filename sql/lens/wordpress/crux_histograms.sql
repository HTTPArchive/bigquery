INNER JOIN
  (
  SELECT
    url,
    _TABLE_SUFFIX AS _TABLE_SUFFIX
  FROM
    `httparchive.technologies.${YYYY_MM_DD}_*`
  WHERE
    app = 'WordPress' and
    LENGTH(url) > 0
  GROUP BY
    1,
    2
  )
ON (SUBSTR(url, 0, LENGTH(url) -1) = origin AND form_factor.name = IF(_TABLE_SUFFIX = 'desktop', 'desktop', 'phone'))
