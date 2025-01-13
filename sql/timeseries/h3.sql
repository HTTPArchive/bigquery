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
  FORMAT_TIMESTAMP('%Y_%m_%d', date) AS date,
  UNIX_DATE(date) * 1000 * 60 * 60 * 24 AS timestamp,
  client,
  ROUND(
    SUM(
      IF(
        LAX_STRING(summary.respHttpVersion) IN ('HTTP/3', 'h3', 'h3-29') OR
        REGEXP_EXTRACT(REGEXP_EXTRACT(resp.value, r'(.*)'), r'(.*?)(?:, [^ ]* = .*)?$') LIKE '%h3=%' OR
        REGEXP_EXTRACT(REGEXP_EXTRACT(resp.value, r'(.*)'), r'(.*?)(?:, [^ ]* = .*)?$') LIKE '%h3-29=%',
        1, 0
      )
    ) * 100 / COUNT(0), 2
  ) AS percent
FROM
  `httparchive.crawl.requests`
LEFT OUTER JOIN
  UNNEST (response_headers) AS resp ON (resp.name = 'alt-svc')
WHERE
  date >= '2020-01-01' AND
  is_root_page
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client
