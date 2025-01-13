#standardSQL
SELECT
  SUBSTR(_TABLE_SUFFIX, 0, 10) AS date,
  UNIX_DATE(CAST(REPLACE(SUBSTR(_TABLE_SUFFIX, 0, 10), '_', '-') AS DATE)) * 1000 * 60 * 60 * 24 AS timestamp,
  IF(ENDS_WITH(_TABLE_SUFFIX, 'desktop'), 'desktop', 'mobile') AS client,
  ROUND(APPROX_QUANTILES(value, 1000)[OFFSET(100)], 2) AS p10,
  ROUND(APPROX_QUANTILES(value, 1000)[OFFSET(250)], 2) AS p25,
  ROUND(APPROX_QUANTILES(value, 1000)[OFFSET(500)], 2) AS p50,
  ROUND(APPROX_QUANTILES(value, 1000)[OFFSET(750)], 2) AS p75,
  ROUND(APPROX_QUANTILES(value, 1000)[OFFSET(900)], 2) AS p90
FROM (
  SELECT
    _TABLE_SUFFIX AS _TABLE_SUFFIX,
    CAST(IFNULL(
      JSON_EXTRACT(report, '$.audits.interactive.numericValue'),
      IFNULL(
        JSON_EXTRACT(report, '$.audits.interactive.rawValue'),
        JSON_EXTRACT(report, '$.audits.consistently-interactive.rawValue')
      )
    ) AS FLOAT64) / 1000 AS value
  FROM
    `httparchive.lighthouse.*`
  WHERE
    _TABLE_SUFFIX < '2022_03_01'
)
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client
