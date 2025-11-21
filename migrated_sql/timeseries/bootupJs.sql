SELECT
  FORMAT_TIMESTAMP('%Y_%m_%d', date) AS date,
  UNIX_DATE(date) * 1000 * 60 * 60 * 24 AS timestamp,
  client,
  ROUND(APPROX_QUANTILES(value, 1000)[OFFSET(100)], 2) AS p10,
  ROUND(APPROX_QUANTILES(value, 1000)[OFFSET(250)], 2) AS p25,
  ROUND(APPROX_QUANTILES(value, 1000)[OFFSET(500)], 2) AS p50,
  ROUND(APPROX_QUANTILES(value, 1000)[OFFSET(750)], 2) AS p75,
  ROUND(APPROX_QUANTILES(value, 1000)[OFFSET(900)], 2) AS p90
FROM (
  SELECT
    date,
    client,
    IFNULL(
      FLOAT64(lighthouse.audits['bootup-time'].numericValue),
      FLOAT64(lighthouse.audits['bootup-time'].rawValue)
    ) / 1000 AS value
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
