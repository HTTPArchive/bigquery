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
      _TABLE_SUFFIX AS _TABLE_SUFFIX,
      url AS tech_url
    FROM
      `httparchive.technologies.*`
    WHERE
      app = 'WordPress'
    GROUP BY
      1,
      2
  )
ON (url = tech_url AND _TABLE_SUFFIX = FORMAT_DATE('%Y_%m_%d', yyyymmdd) || "_" || client)
JOIN (
  SELECT
    yyyymmdd,
    client,
    COUNT(DISTINCT url) AS total
  FROM `httparchive.blink_features.features`
  JOIN
    (
      SELECT
        _TABLE_SUFFIX AS _TABLE_SUFFIX,
        url AS tech_url
      FROM
        `httparchive.technologies.*`
      WHERE
        app = 'WordPress'
      GROUP BY
        1,
        2
    )
  ON (url = tech_url AND _TABLE_SUFFIX = FORMAT_DATE('%Y_%m_%d', yyyymmdd) || "_" || client)
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
