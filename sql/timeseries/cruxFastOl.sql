#standardSQL
SELECT
  REGEXP_REPLACE(_TABLE_SUFFIX, '(\\d{4})(\\d{2})', '\\1_\\2_01') AS date,
  UNIX_DATE(CAST(REGEXP_REPLACE(_TABLE_SUFFIX, '(\\d{4})(\\d{2})', '\\1-\\2-01') AS DATE)) * 1000 * 60 * 60 * 24 AS timestamp,
  IF(form_factor.name = 'desktop', 'desktop', 'mobile') AS client,
  ROUND(SUM(IF(ol.start < 1000, ol.density, 0)) * 100 / SUM(ol.density), 2) AS percent
FROM
  `chrome-ux-report.all.*`,
  UNNEST(onload.histogram.bin) AS ol
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client