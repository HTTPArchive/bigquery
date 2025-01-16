INNER JOIN (
  SELECT
    SUBSTR(page, 0, LENGTH(page) - 1) AS origin,
    IF(client = 'mobile', 'phone', client) AS device,
    date
  FROM
    `httparchive.crawl.pages`
  WHERE
    date >= '2010-11-15' AND
    is_root_page AND
    'WordPress' IN UNNEST(technologies.technology)
  GROUP BY
    1,
    2,
    3
)
USING (origin, device, date)
