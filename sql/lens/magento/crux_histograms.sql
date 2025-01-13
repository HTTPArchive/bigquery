INNER JOIN
  (
  SELECT
    page,
    client
  FROM
    `httparchive.crawl.pages`
  WHERE
    date = '${YYYY-MM-DD}' AND
    'Magento' in UNNEST(technologies.technology)
  GROUP BY
    1,
    2
  )
ON (SUBSTR(page, 0, LENGTH(page) -1) = origin AND form_factor.name = IF(client = 'desktop', 'desktop', 'phone'))
