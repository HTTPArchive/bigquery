#standardSQL
CREATE TEMPORARY FUNCTION
  getPWAScore(report STRING)
  RETURNS FLOAT64
  LANGUAGE js AS """
$=JSON.parse(report);
return $.reportCategories.find(i => i.name === 'Progressive Web App').score;
""";
CREATE TABLE IF NOT EXISTS
  `scratchspace.lighthouse_pwas` AS
SELECT
  DISTINCT url AS pwa_url,
  IFNULL(rank,
    1000000) AS rank,
  date,
  platform,
  CAST(ROUND(score) AS INT64) AS lighthouse_pwa_score
FROM (
  SELECT
    REGEXP_REPLACE(JSON_EXTRACT(report,
        "$.url"), "\"", "") AS url,
    getPWAScore(report) AS score,
    REGEXP_REPLACE(REGEXP_EXTRACT(_TABLE_SUFFIX, "\\d{4}(?:_\\d{2}){2}"), "_", "-") AS date,
    REGEXP_EXTRACT(_TABLE_SUFFIX, ".*_(\\w+)$") AS platform
  FROM
    `httparchive.lighthouse.*`
  WHERE
    report IS NOT NULL
    AND JSON_EXTRACT(report,
      "$.audits.service-worker.score") = 'true' )
LEFT JOIN (
  SELECT
    Alexa_rank AS rank,
    Alexa_domain AS domain
  FROM
    # Hard-coded due to https://github.com/HTTPArchive/bigquery/issues/42
    `httparchive.urls.20170315`
  WHERE
    Alexa_rank IS NOT NULL
    AND Alexa_domain IS NOT NULL ) AS urls
ON
  urls.domain = NET.REG_DOMAIN(url)
WHERE
  # Lighthouse "Good" threshold
  score >= 75
GROUP BY
  url,
  date,
  score,
  platform,
  date,
  rank
ORDER BY
  rank ASC,
  url,
  date DESC;