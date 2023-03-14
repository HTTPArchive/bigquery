#standardSQL
# The amount of requests either using HTTP/3 or able to use it.
#
# We measure "ability to use" as well as "actual use", as HTTP Archive is a
# cold crawl and so less likely to use HTTP/3 which requires prior visits.
#
# For "able to use" we look at the alt-svc response header.
#
# We also only measure official HTTP/3 (ALPN h3, h3-29) and not gQUIC or other
# prior versions. h3-29 is the final draft version and will be switched to h3
# when HTTP/3 is approved so we include that as it is HTTP/3 in all but name.
#
SELECT
  SUBSTR(_TABLE_SUFFIX, 0, 10) AS date,
  UNIX_DATE(CAST(REPLACE(SUBSTR(_TABLE_SUFFIX, 0, 10), '_', '-') AS DATE)) * 1000 * 60 * 60 * 24 AS timestamp,
  IF(ENDS_WITH(_TABLE_SUFFIX, 'desktop'), 'desktop', 'mobile') AS client,
  ROUND(
    SUM(
      IF(
        respHttpVersion IN ('HTTP/3', 'h3', 'h3-29') OR
        reqHttpVersion IN ('HTTP/3', 'h3', 'h3-29') OR
        REGEXP_EXTRACT(REGEXP_EXTRACT(respOtherHeaders, r'alt-svc = (.*)'), r'(.*?)(?:, [^ ]* = .*)?$') LIKE '%h3=%' OR
        REGEXP_EXTRACT(REGEXP_EXTRACT(respOtherHeaders, r'alt-svc = (.*)'), r'(.*?)(?:, [^ ]* = .*)?$') LIKE '%h3-29=%',
        1, 0
      )
    ) * 100 / COUNT(0), 2
  ) AS percent
FROM
  `httparchive.summary_requests.*`
WHERE
  SUBSTR(_TABLE_SUFFIX, 0, 10) >= '2020_01_01'
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client
