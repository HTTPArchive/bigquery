#standardSQL
SELECT -- noqa: disable=L044
  *
FROM
  `httparchive.core_web_vitals.technologies`
WHERE
  app = '%APP%' AND
  geo = '%GEO%' AND
  rank = '%RANK%'
ORDER BY
  date DESC
