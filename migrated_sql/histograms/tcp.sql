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
      INT64(summary._connections) AS bin
    FROM
      `httparchive.crawl.pages`
    WHERE
      date = '${YYYY-MM-DD}' AND
      is_root_page AND
      INT64(summary._connections) > 0
    GROUP BY
      bin,
      client
  )
)
ORDER BY
  bin,
  client
