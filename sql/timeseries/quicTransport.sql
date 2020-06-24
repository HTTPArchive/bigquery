#standardSQL
SELECT
  SUBSTR(_TABLE_SUFFIX, 0, 10) AS date,
  UNIX_DATE(CAST(REPLACE(SUBSTR(_TABLE_SUFFIX, 0, 10), '_', '-') AS DATE)) * 1000 * 60 * 60 * 24 AS timestamp,
  IF(ENDS_WITH(_TABLE_SUFFIX, 'desktop'), 'desktop', 'mobile') AS client,
  ROUND(SUM(IF(IFNULL(
    JSON_EXTRACT(payload, '$._blinkFeatureFirstUsed.Features.QuicTransport'),
    JSON_EXTRACT(payload, '$._blinkFeatureFirstUsed.Features.3184'))
  IS NOT NULL, 1, 0)) * 100 / COUNT(0), 5) AS percent
FROM
  `httparchive.pages.*`
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client