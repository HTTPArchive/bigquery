#standardSQL
CREATE TEMPORARY FUNCTION countVulnerabilities(report STRING)
RETURNS INT64 LANGUAGE js AS  """
  try {
    const $ = JSON.parse(report);
    const audit = $.audits['no-vulnerable-libraries'];
    if (audit.extendedInfo && audit.extendedInfo.vulnerabilities) {
      return audit.extendedInfo.vulnerabilities.length;
    }
    return +audit.displayValue.match(/\\d+/)[0];
  } catch (e) {
    return 0;
  }
""";

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
      countVulnerabilities(report) AS bin
    FROM
      `httparchive.lighthouse.${YYYY_MM_DD}_*`
    WHERE
      report IS NOT NULL
    GROUP BY
      bin,
      client ) )
ORDER BY
  bin,
  client
