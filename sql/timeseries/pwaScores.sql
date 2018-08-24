#standardSQL
CREATE TEMPORARY FUNCTION
  getPWAScore(report STRING)
  RETURNS FLOAT64
  LANGUAGE js AS """
$=JSON.parse(report);
return $.reportCategories.find(i => i.name === 'Progressive Web App').score;
""";
SELECT
  date,
  UNIX_MILLIS(TIMESTAMP(REGEXP_REPLACE(date, "_", "-"))) AS timestamp,
  client,
  ROUND(APPROX_QUANTILES(lighthouse_pwa_score, 101)[
  OFFSET
    (11)], 2) AS p10,
  ROUND(APPROX_QUANTILES(lighthouse_pwa_score, 101)[
  OFFSET
    (26)], 2) AS p25,
  ROUND(APPROX_QUANTILES(lighthouse_pwa_score, 101)[
  OFFSET
    (51)], 2) AS p50,
  ROUND(APPROX_QUANTILES(lighthouse_pwa_score, 101)[
  OFFSET
    (76)], 2) AS p75,
  ROUND(APPROX_QUANTILES(lighthouse_pwa_score, 101)[
  OFFSET
    (91)], 2) AS p90
FROM (
  SELECT
    getPWAScore(report) AS lighthouse_pwa_score,
    REGEXP_EXTRACT(_TABLE_SUFFIX, "\\d{4}(?:_\\d{2}){2}") AS date,
    REGEXP_EXTRACT(_TABLE_SUFFIX, ".*_(\\w+)$") AS client
  FROM
    `httparchive.lighthouse.*`
  WHERE
    report IS NOT NULL
    AND JSON_EXTRACT(report,
      "$.audits.service-worker.score") = 'true' )
GROUP BY
  date,
  client
ORDER BY
  date,
  client;