#standardSQL
CREATE TABLE IF NOT EXISTS
  `progressive_web_apps.service_workers` AS
SELECT
  pwa_url,
  rank,
  sw_url,
  date,
  platform,
  REGEXP_CONTAINS(sw_code, r"\.oninstall\s*=|addEventListener\(\s*[\"']install[\"']") AS install_event,
  REGEXP_CONTAINS(sw_code, r"\.onactivate\s*=|addEventListener\(\s*[\"']activate[\"']") AS activate_event,
  REGEXP_CONTAINS(sw_code, r"\.onfetch\s*=|addEventListener\(\s*[\"']fetch[\"']") AS fetch_event,
  REGEXP_CONTAINS(sw_code, r"\.onpush\s*=|addEventListener\(\s*[\"']push[\"']") AS push_event,
  REGEXP_CONTAINS(sw_code, r"\.onnotificationclick\s*=|addEventListener\(\s*[\"']notificationclick[\"']") AS notificationclick_event,
  REGEXP_CONTAINS(sw_code, r"\.onnotificationclose\s*=|addEventListener\(\s*[\"']notificationclose[\"']") AS notificationclose_event,
  REGEXP_CONTAINS(sw_code, r"\.onsync\s*=|addEventListener\(\s*[\"']sync[\"']") AS sync_event,
  REGEXP_CONTAINS(sw_code, r"\.oncanmakepayment\s*=|addEventListener\(\s*[\"']canmakepayment[\"']") AS canmakepayment_event,
  REGEXP_CONTAINS(sw_code, r"\.onpaymentrequest\s*=|addEventListener\(\s*[\"']paymentrequest[\"']") AS paymentrequest_event,
  REGEXP_CONTAINS(sw_code, r"\.onmessage\s*=|addEventListener\(\s*[\"']message[\"']") AS message_event,
  REGEXP_CONTAINS(sw_code, r"\.onmessageerror\s*=|addEventListener\(\s*[\"']messageerror[\"']") AS messageerror_event,
  REGEXP_CONTAINS(sw_code, r"new Workbox|new workbox|workbox\.precaching\.|workbox\.strategies\.") AS uses_workboxjs
FROM
  `progressive_web_apps.pwa_candidates`
JOIN (
  SELECT
    url,
    body AS sw_code,
    REGEXP_REPLACE(REGEXP_EXTRACT(_TABLE_SUFFIX, "\\d{4}(?:_\\d{2}){2}"), "_", "-") AS date,
    REGEXP_EXTRACT(_TABLE_SUFFIX, ".*_(\\w+)$") AS platform
  FROM
    `httparchive.response_bodies.*`
  WHERE
    body IS NOT NULL
    AND body != ""
    AND url IN (
    SELECT
      DISTINCT sw_url
    FROM
      `progressive_web_apps.pwa_candidates`) ) AS sw_bodies
ON
  sw_bodies.url = sw_url
ORDER BY
  rank ASC,
  pwa_url,
  date DESC,
  platform,
  sw_url;