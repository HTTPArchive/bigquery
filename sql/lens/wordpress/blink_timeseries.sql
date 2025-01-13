SELECT
  REGEXP_REPLACE(CAST(yyyymmdd AS STRING), '-', '') AS yyyymmdd,
  client,
  id,
  feature,
  type,
  COUNT(0) AS num_urls,
  MAX(total) AS total_urls,
  SAFE_DIVIDE(COUNT(0), max(total)) AS num_urls_pct
FROM
  `httparchive.blink_features.features`
JOIN
  (
    SELECT
      page,
      client AS page_client,
      date,
      url AS tech_url
    FROM
      `httparchive.crawl.pages`
    WHERE
      date >= '2016-11-15' AND
      app = 'WordPress'
    GROUP BY
      client,
      date,
      page
  )
ON (url = page AND yyyymmdd = date AND client = page_client)
JOIN (
  SELECT
    yyyymmdd,
    client,
    COUNT(DISTINCT url) AS total
  FROM `httparchive.blink_features.features`
  JOIN
    (
      SELECT
        page,
        client AS page_client,
        date,
        url AS tech_url
      FROM
        `httparchive.crawl.pages`
      WHERE
        date >= '2017-01-01' AND
        app = 'WordPress'
      GROUP BY
        client,
        date,
        page
    )
  ON (url = page AND yyyymmdd = date AND client = page_client)
  WHERE
    1 = 1
    {{ BLINK_DATE_JOIN }}
  GROUP BY
    yyyymmdd,
    client
)
USING (yyyymmdd, client)
WHERE
  1 = 1
  {{ BLINK_DATE_JOIN }}
GROUP BY
  yyyymmdd,
  client,
  id,
  feature,
  type
ORDER BY
  yyyymmdd,
  client,
  id,
  feature,
  type
