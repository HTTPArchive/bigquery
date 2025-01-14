#standardSQL
# Lighthouse changed format of scores in v3.0.0 released in July 2018 so handle old with a UDF
CREATE TEMPORARY FUNCTION getA11yScore(reportCategories JSON)
RETURNS FLOAT64 DETERMINISTIC
LANGUAGE js AS """
  if(reportCategories) {
    return reportCategories.find(i => i.name === 'Accessibility').score;
  }
""";

SELECT
  FORMAT_TIMESTAMP('%Y_%m_%d', date) AS date,
  UNIX_DATE(date) * 1000 * 60 * 60 * 24 AS timestamp,
  client,
  ROUND(APPROX_QUANTILES(score, 1000)[OFFSET(100)], 2) AS p10,
  ROUND(APPROX_QUANTILES(score, 1000)[OFFSET(250)], 2) AS p25,
  ROUND(APPROX_QUANTILES(score, 1000)[OFFSET(500)], 2) AS p50,
  ROUND(APPROX_QUANTILES(score, 1000)[OFFSET(750)], 2) AS p75,
  ROUND(APPROX_QUANTILES(score, 1000)[OFFSET(900)], 2) AS p90
FROM (
  SELECT
    date,
    client,
    IFNULL(LAX_FLOAT64(lighthouse.categories.accessibility.score) * 100, getA11yScore(lighthouse.reportCategories)) AS score
  FROM
    `httparchive.crawl.pages`
  WHERE
    lighthouse IS NOT NULL AND
    TO_JSON_STRING(lighthouse) != '{}' AND
    date >= '2017-06-01' AND
    is_root_page
)
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client
