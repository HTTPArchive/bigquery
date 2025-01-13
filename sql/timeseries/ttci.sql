#standardSQL
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
    client,
    date,
    IFNULL(
      FLOAT64(lighthouse.audits.interactive.numericValue),
      IFNULL(
        FLOAT64(lighthouse.audits.interactive.rawValue),
        FLOAT64(lighthouse.audits['consistently-interactive].rawValue)
      )
    ) / 1000 AS value
  FROM
    `httparchive.crawl.pages`
  WHERE
    is_root_page AND
    date >= '2016-01-01'
)
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client
