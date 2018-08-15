#standardSQL
CREATE TABLE IF NOT EXISTS
  `scratchspace.usecounters_pwas` AS
SELECT
  DISTINCT REGEXP_REPLACE(url, "^http:", "https:") AS pwa_url,
  IFNULL(rank,
    1000000) AS rank,
  date,
  platform
FROM (
  SELECT
    DISTINCT url,
    REGEXP_REPLACE(REGEXP_EXTRACT(_TABLE_SUFFIX, "\\d{4}(?:_\\d{2}){2}"), "_", "-") AS date,
    REGEXP_EXTRACT(_TABLE_SUFFIX, ".*_(\\w+)$") AS platform
  FROM
    `httparchive.pages.*`
  WHERE
    # From https://cs.chromium.org/chromium/src/third_party/blink/public/platform/web_feature.mojom
    JSON_EXTRACT(payload,
      '$._blinkFeatureFirstUsed.Features.ServiceWorkerControlledPage') IS NOT NULL)
LEFT JOIN (
  SELECT
    Alexa_domain AS domain,
    Alexa_rank AS rank
  FROM
    # Hard-coded due to https://github.com/HTTPArchive/bigquery/issues/42
    `httparchive.urls.20170315` AS urls
  WHERE
    Alexa_rank IS NOT NULL
    AND Alexa_domain IS NOT NULL )
ON
  domain = NET.REG_DOMAIN(url)
ORDER BY
  rank ASC,
  date DESC,
  pwa_url;