#standardSQL
SELECT
  *,
  SUM(pdf) OVER (PARTITION BY client ORDER BY bin) AS cdf
FROM (
    SELECT
      client,
      COUNT(0) AS volume,
      FLOOR(FLOAT64(IFNULL(lighthouse.audits['bootup-time'].numericValue, lighthouse.audits['bootup-time'].rawValue)) / 100) / 10 AS bin
    FROM
      `httparchive.crawl.pages`
    WHERE
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
