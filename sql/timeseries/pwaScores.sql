#standardSQL
# Lighthouse changed format of scores in v3.0.0 released in July 2018 so handle old with a UDF
CREATE TEMPORARY FUNCTION getPWAScore(reportCategories STRING)
RETURNS FLOAT64 DETERMINISTIC
LANGUAGE js AS """
  $=JSON.parse(reportCategories);
  if ($) {
    return $.find(i => i.name === 'Progressive Web App').score;
  }
""";

SELECT
  date,
  UNIX_DATE(CAST(REPLACE(date, '_', '-') AS DATE)) * 1000 * 60 * 60 * 24 AS timestamp,
  client,
  ROUND(APPROX_QUANTILES(score, 1000)[OFFSET(100)], 2) AS p10,
  ROUND(APPROX_QUANTILES(score, 1000)[OFFSET(250)], 2) AS p25,
  ROUND(APPROX_QUANTILES(score, 1000)[OFFSET(500)], 2) AS p50,
  ROUND(APPROX_QUANTILES(score, 1000)[OFFSET(750)], 2) AS p75,
  ROUND(APPROX_QUANTILES(score, 1000)[OFFSET(900)], 2) AS p90
FROM (
  SELECT
    SUBSTR(_TABLE_SUFFIX, 0, 10) AS date,
    IF(ENDS_WITH(_TABLE_SUFFIX, 'desktop'), 'desktop', 'mobile') AS client,
    IFNULL(CAST(JSON_EXTRACT(report, '$.categories.pwa.score') AS FLOAT64) * 100, getPWAScore(JSON_EXTRACT(report, '$.reportCategories'))) AS score
  FROM
    `httparchive.lighthouse.*`
  WHERE
    report IS NOT NULL
    AND (JSON_EXTRACT(report, "$.audits.service-worker.score") = 'true'
         OR JSON_EXTRACT(report, "$.audits.service-worker.score") = '1')
)
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client;
