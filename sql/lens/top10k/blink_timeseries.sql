SELECT
  f.yyyymmdd,
  f.client,
  f.id,
  f.feature,
  f.type,
  COUNT(1) as num_urls,
  MAX(total) AS total_urls,
  COUNT(1) / max(total) as num_urls_pct
FROM
  `httparchive.blink_features.features` f,
  `httparchive.summary_pages.*` sp,
  (SELECT _TABLE_SUFFIX, COUNT(DISTINCT url) as total FROM `httparchive.summary_pages.*` WHERE rank <= 10000 and _TABLE_SUFFIX >= '2021_05_01' GROUP BY _TABLE_SUFFIX) AS t
WHERE
  REPLACE(SUBSTRING(sp._TABLE_SUFFIX,1,10),'_','') = f.yyyymmdd AND
  SUBSTRING(sp._TABLE_SUFFIX,12) = f.client AND
  sp._TABLE_SUFFIX = t._TABLE_SUFFIX AND
  sp.url = f.url AND
  sp.rank <= 10000 AND
  sp._TABLE_SUFFIX >= '2021_05_01'
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
