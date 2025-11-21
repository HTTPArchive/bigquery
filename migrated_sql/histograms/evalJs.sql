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
      CAST(FLOAT64(r.payload['_cpu.EvaluateScript']) / 20 AS INT64) * 20 AS bin
    FROM
      `httparchive.crawl.requests` r
    INNER JOIN
      `httparchive.crawl.pages`
    USING (date, client, is_root_page, rank, page)
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
