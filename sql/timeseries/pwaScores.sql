#standardSQL
CREATE TEMPORARY FUNCTION getPWAScore(report STRING)
RETURNS FLOAT64
LANGUAGE js AS """
  $=JSON.parse(report);
  if ($.reportCategories) {
    return $.reportCategories.find(i => i.name === 'Progressive Web App').score;
  } else {
    return $.categories.pwa.score * 100;
  }
""";

SELECT
  SUBSTR(_TABLE_SUFFIX, 0, 10) AS date,
  UNIX_DATE(CAST(REPLACE(SUBSTR(_TABLE_SUFFIX, 0, 10), '_', '-') AS DATE)) * 1000 * 60 * 60 * 24 AS timestamp,
  IF(ENDS_WITH(_TABLE_SUFFIX, 'desktop'), 'desktop', 'mobile') AS client,
  ROUND(APPROX_QUANTILES(getPWAScore(report), 101)[OFFSET(11)], 2) AS p10,
  ROUND(APPROX_QUANTILES(getPWAScore(report), 101)[OFFSET(26)], 2) AS p25,
  ROUND(APPROX_QUANTILES(getPWAScore(report), 101)[OFFSET(51)], 2) AS p50,
  ROUND(APPROX_QUANTILES(getPWAScore(report), 101)[OFFSET(76)], 2) AS p75,
  ROUND(APPROX_QUANTILES(getPWAScore(report), 101)[OFFSET(91)], 2) AS p90
FROM
  `httparchive.lighthouse.*`
WHERE
  report IS NOT NULL
  AND (JSON_EXTRACT(report, "$.audits.service-worker.score") = 'true'
    OR JSON_EXTRACT(report, "$.audits.service-worker.score") = '1')
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client;