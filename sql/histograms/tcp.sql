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
      _connections AS bin
    FROM
      `httparchive.summary_pages.${YYYY_MM_DD}_*`
    WHERE
      _connections > 0
    GROUP BY
      bin,
      client))
ORDER BY
  bin,
  client
