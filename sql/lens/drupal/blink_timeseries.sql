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
      PARSE_DATE('%Y_%m_%d', SUBSTR(_TABLE_SUFFIX, 0, 10)) AS yyyymmdd,
      SUBSTR(_TABLE_SUFFIX, 12) AS client,
      url
    FROM
      `httparchive.technologies.*`
    WHERE
      app = 'Drupal' AND
      LENGTH(url) > 0
    GROUP BY
      1,
      2,
      3
  )
USING (yyyymmdd, url, client)
JOIN (
  SELECT
    yyyymmdd,
    client,
    COUNT(DISTINCT url) AS total
  FROM `httparchive.blink_features.features`
  JOIN
    (
      SELECT
        PARSE_DATE('%Y_%m_%d', SUBSTR(_TABLE_SUFFIX, 0, 10)) AS yyyymmdd,
        SUBSTR(_TABLE_SUFFIX, 12) AS client,
        url
      FROM
        `httparchive.technologies.*`
      WHERE
        app = 'Drupal' AND
        LENGTH(url) > 0
      GROUP BY
        1,
        2,
        3
    )
  USING (yyyymmdd, url, client)
  WHERE 1 = 1
{{ BLINK_DATE_JOIN }}
  GROUP BY
    yyyymmdd,
    client
  )
USING (yyyymmdd, client)
WHERE 1 = 1
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
