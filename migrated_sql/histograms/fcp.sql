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
      CAST(FLOOR(FLOAT64(payload['_chromeUserTiming.firstContentfulPaint']) / 1000) AS INT64) AS bin
    FROM
      `httparchive.crawl.pages`
    WHERE
      date = '${YYYY-MM-DD}' AND
      is_root_page
    GROUP BY
      bin,
      client
    HAVING
      bin IS NOT NULL AND
      bin >= 0
  )
)
ORDER BY
  bin,
  client
