#standardSQL
SELECT
  geo,
  MAX(origins) AS num_origins
FROM
  `httparchive.core_web_vitals.technologies`
WHERE
  date >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
GROUP BY
  geo
HAVING
  num_origins > 500
ORDER BY
  num_origins DESC;
