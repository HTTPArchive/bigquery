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
      _TABLE_SUFFIX AS client,
      COUNT(0) AS volume,
      FLOOR(onContentLoaded / 1000) AS bin
    FROM
      `httparchive.summary_pages.${YYYY_MM_DD}_*`
    WHERE
      onContentLoaded > 0
    GROUP BY
      bin,
      client
  )
)
ORDER BY
  bin,
  client
