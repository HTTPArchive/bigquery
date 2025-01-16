#standardSQL
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
      FLOOR(FLOAT64(summary.onContentLoaded) / 1000) AS bin
    FROM
      `httparchive.crawl.pages`
    WHERE
      date = '${YYYY-MM-DD}' AND
      is_root_page AND
      FLOAT64(summary.onContentLoaded) > 0
    GROUP BY
      bin,
      client
  )
)
ORDER BY
  bin,
  client
