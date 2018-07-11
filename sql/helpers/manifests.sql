#standardSQL
  CREATE TABLE IF NOT EXISTS `progressive_web_apps.web_app_manifests` AS
SELECT
  pwa_url,
  rank,
  manifest_url,
  date,
  platform,
  REGEXP_CONTAINS(manifest_code,
    r"\"dir\"\s*:") AS dir_property,
  REGEXP_CONTAINS(manifest_code,
    r"\"lang\"\s*:") AS lang_property,
  REGEXP_CONTAINS(manifest_code,
    r"\"name\"\s*:") AS name_property,
  REGEXP_CONTAINS(manifest_code,
    r"\"short_name\"\s*:") AS short_name_property,
  REGEXP_CONTAINS(manifest_code,
    r"\"description\"\s*:") AS description_property,
  REGEXP_CONTAINS(manifest_code,
    r"\"scope\"\s*:") AS scope_property,
  REGEXP_CONTAINS(manifest_code,
    r"\"icons\"\s*:") AS icons_property,
  REGEXP_CONTAINS(manifest_code,
    r"\"display\"\s*:") AS display_property,
  REGEXP_CONTAINS(manifest_code,
    r"\"orientation\"\s*:") AS orientation_property,
  REGEXP_CONTAINS(manifest_code,
    r"\"start_url\"\s*:") AS start_url_property,
  REGEXP_CONTAINS(manifest_code,
    r"\"serviceworker\"\s*:") AS serviceworker_property,
  REGEXP_CONTAINS(manifest_code,
    r"\"theme_color\"\s*:") AS theme_color_property,
  REGEXP_CONTAINS(manifest_code,
    r"\"related_applications\"\s*:") AS related_applications_property,
  REGEXP_CONTAINS(manifest_code,
    r"\"prefer_related_applications\"\s*:") AS prefer_related_applications_property,
  REGEXP_CONTAINS(manifest_code,
    r"\"background_color\"\s*:") AS background_color_property,
  REGEXP_CONTAINS(manifest_code,
    r"\"categories\"\s*:") AS categories_property,
  REGEXP_CONTAINS(manifest_code,
    r"\"screenshots\"\s*:") AS screenshots_property,
  REGEXP_CONTAINS(manifest_code,
    r"\"iarc_rating_id\"\s*:") AS iarc_rating_id_property,
  REGEXP_CONTAINS(manifest_code,
    r"\"gcm_sender_id\"\s*:") AS gcm_sender_id_property,
  REGEXP_CONTAINS(manifest_code,
    r"\"gcm_user_visible_only\"\s*:") AS gcm_user_visible_only_property,
  REGEXP_CONTAINS(manifest_code,
    r"\"share_target\"\s*:") AS share_target_property,
  REGEXP_CONTAINS(manifest_code,
    r"\"supports_share\"\s*:") AS supports_share_property
FROM
  `progressive_web_apps.pwa_candidates`
JOIN (
  SELECT
    url,
    body AS manifest_code,
    REGEXP_REPLACE(REGEXP_EXTRACT(_TABLE_SUFFIX, "\\d{4}(?:_\\d{2}){2}"), "_", "-") AS date,
    REGEXP_EXTRACT(_TABLE_SUFFIX, ".*_(\\w+)$") AS platform
  FROM
    `httparchive.response_bodies.*`
  WHERE
    body IS NOT NULL
    AND body != ""
    AND url IN (
    SELECT
      DISTINCT manifest_url
    FROM
      `progressive_web_apps.pwa_candidates`) ) AS manifest_bodies
ON
  manifest_bodies.url = manifest_url
ORDER BY
  rank ASC,
  pwa_url,
  date DESC,
  platform,
  manifest_url;