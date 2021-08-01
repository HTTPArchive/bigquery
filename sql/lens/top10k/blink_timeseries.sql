SELECT
  REGEXP_REPLACE(CAST(f.yyyymmdd AS STRING),'-','') AS yyyymmdd,
  f.client,
  f.id,
  f.feature,
  f.type,
  COUNT(1) AS num_urls,
  MAX(total) AS total_urls,
  SAFE_DIVIDE(COUNT(1), max(total)) AS num_urls_pct
FROM
  `httparchive.blink_features.features` f,
  `httparchive.summary_pages.*` sp,
  (SELECT _TABLE_SUFFIX, COUNT(DISTINCT url) AS total FROM `httparchive.summary_pages.*` WHERE rank <= 10000 AND _TABLE_SUFFIX >= '2021_05_01' GROUP BY _TABLE_SUFFIX) AS t
WHERE
  REGEXP_REPLACE(SUBSTRING(sp._TABLE_SUFFIX,1,10),'_','-') = CAST(f.yyyymmdd as STRING) AND
  SUBSTRING(sp._TABLE_SUFFIX,12) = f.client AND
  sp._TABLE_SUFFIX = t._TABLE_SUFFIX AND
  sp.url = f.url AND
  sp.rank <= 10000 AND
  f.yyyymmdd >= '2021-05-01' BLINK_DATE_JOIN
GROUP BY
  f.yyyymmdd,
  f.client,
  f.id,
  f.feature,
  f.type,
  sp._TABLE_SUFFIX
ORDER BY
  f.yyyymmdd,
  f.client,
  f.id,
  f.feature,
  f.type
