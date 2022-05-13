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
      IF(form_factor.name = 'desktop', 'desktop', 'mobile') AS client,
      bin.start AS bin,
      SUM(bin.density) AS volume
    FROM (
      SELECT
        form_factor,
        experimental.time_to_first_byte.histogram.bin AS bins
      FROM
        `chrome-ux-report.all.${YYYYMM}`)
    CROSS JOIN
      UNNEST(bins) AS bin
    GROUP BY
      bin,
      client ) )
ORDER BY
  bin,
  client
