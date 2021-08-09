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
JOIN (
  SELECT
    yyyymmdd,
    client,
    COUNT(DISTINCT url) AS total
  FROM `httparchive.blink_features.features`
  WHERE
    rank <= 1000 AND
    yyyymmdd >= '2021-05-01' BLINK_DATE_JOIN
  GROUP BY
    yyyymmdd,
    client
  )
USING (yyyymmdd, client)
WHERE
  rank <= 1000 AND
  yyyymmdd >= '2021-05-01' BLINK_DATE_JOIN
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
