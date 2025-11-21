SELECT
  *,
  SUM(pdf) OVER (PARTITION BY client ORDER BY bin) AS cdf
FROM (
  SELECT
    *,
    volume / SUM(volume) OVER (PARTITION BY client) AS pdf
  FROM (
    SELECT
      client,
      COUNT(0) AS volume,
      CAST(FLOOR(CAST(IFNULL(
        FLOAT64(lighthouse.audits.interactive.numericValue),
        IFNULL(
          FLOAT64(lighthouse.audits['consistently-interactive'].rawValue),
          FLOAT64(lighthouse.audits.interactive.rawValue)
        )
      ) AS FLOAT64) / 1000) AS INT64) AS bin
    FROM
      `httparchive.crawl.pages`
    WHERE
      date >= '2022-03-01' AND
      date = '${YYYY-MM-DD}' AND
      is_root_page
    GROUP BY
      bin,
      client
    HAVING
      bin IS NOT NULL
  )
)
ORDER BY
  bin,
  client
