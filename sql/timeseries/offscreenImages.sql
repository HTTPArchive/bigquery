#standardSQL
SELECT
  FORMAT_TIMESTAMP('%Y_%m_%d', date) AS date,
  UNIX_DATE(date) * 1000 * 60 * 60 * 24 AS timestamp,
  client,
  ROUND(APPROX_QUANTILES(IFNULL(INT64(lighthouse.audits['offscreen-images'].details.overallSavingsBytes), INT64(lighthouse.audits['offscreen-images'].extendedInfo.value.wastedKb) * 1024), 1001)[OFFSET(101)] / 1024, 2) AS p10,
  ROUND(APPROX_QUANTILES(IFNULL(INT64(lighthouse.audits['offscreen-images'].details.overallSavingsBytes), INT64(lighthouse.audits['offscreen-images'].extendedInfo.value.wastedKb) * 1024), 1001)[OFFSET(251)] / 1024, 2) AS p25,
  ROUND(APPROX_QUANTILES(IFNULL(INT64(lighthouse.audits['offscreen-images'].details.overallSavingsBytes), INT64(lighthouse.audits['offscreen-images'].extendedInfo.value.wastedKb) * 1024), 1001)[OFFSET(501)] / 1024, 2) AS p50,
  ROUND(APPROX_QUANTILES(IFNULL(INT64(lighthouse.audits['offscreen-images'].details.overallSavingsBytes), INT64(lighthouse.audits['offscreen-images'].extendedInfo.value.wastedKb) * 1024), 1001)[OFFSET(751)] / 1024, 2) AS p75,
  ROUND(APPROX_QUANTILES(IFNULL(INT64(lighthouse.audits['offscreen-images'].details.overallSavingsBytes), INT64(lighthouse.audits['offscreen-images'].extendedInfo.value.wastedKb) * 1024), 1001)[OFFSET(901)] / 1024, 2) AS p90
FROM
  `httparchive.crawl.pages`
WHERE
  is_root_page AND
  date >= '2017-06-01'
GROUP BY
  date,
  timestamp,
  client
ORDER BY
  date DESC,
  client
