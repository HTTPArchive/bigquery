"""HTTP Archive dataflow pipeline for generating HAR data on BigQuery."""

from __future__ import absolute_import

import argparse
from copy import deepcopy
from datetime import datetime
from hashlib import sha256
import json
import logging
import re

import apache_beam as beam
import apache_beam.io.gcp.gcsio as gcsio
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.options.pipeline_options import SetupOptions


# BigQuery can handle rows up to 100 MB.
MAX_CONTENT_SIZE = 10 * 1024 * 1024


def get_page(har):
  """Parses the page from a HAR object."""

  if not har:
    return

  page = har.get('log').get('pages')[0]
  url = page.get('_URL')
  client = 'unknown'
  wptid = page.get('testID')
  date = '20%s-%s-%s' % (wptid[:2], wptid[2:4], wptid[4:6])
  is_root_page = True
  root_page = url
  rank = None

  metadata = page.get('_metadata')
  if metadata:
    # The page URL from metadata is more accurate.
    # See https://github.com/HTTPArchive/data-pipeline/issues/48
    url = metadata.get('tested_url')
    client = metadata.get('layout', '').lower()
    is_root_page = metadata.get('crawl_depth') == '0'
    root_page = metadata.get('root_page_url')
    rank = int(metadata.get('rank'))

  try:
    payload_json = to_json(page)
  except:
    logging.warning('Skipping pages payload for "%s": unable to stringify as JSON.' % url)
    return

  payload_size = len(payload_json)
  if payload_size > MAX_CONTENT_SIZE:
    logging.warning('Skipping pages payload for "%s": payload size (%s) exceeds the maximum content size of %s bytes.' % (url, payload_size, MAX_CONTENT_SIZE))
    return

  custom_metrics = get_custom_metrics(page)
  lighthouse = get_lighthouse_reports(har)
  features = get_features(page)
  technologies = get_technologies(page)

  return [{
    'date': date,
    'client': client,
    'page': url,
    'is_root_page': is_root_page,
    'root_page': root_page,
    'rank': rank,
    'wptid': wptid,
    'payload': payload_json,
    'summary': '',
    'custom_metrics': custom_metrics,
    'lighthouse': lighthouse,
    'features': features,
    'technologies': technologies,
    'metadata': to_json(metadata)
  }]


def get_custom_metrics(page):
  custom_metrics = {}

  for metric in page.get('_custom'):
    value = page.get(metric)

    if type(value) == type(''):
      try:
        value = json.loads(value)
      except:
        pass

    custom_metrics[metric] = value

  return to_json(custom_metrics)


def get_features(page):
  """Parses the features from a page."""

  if not page:
    return
  
  blink_features = page.get('_blinkFeatureFirstUsed')

  if not blink_features:
    return

  def get_feature_names(feature_map, feature_type):
    try:
      feature_names = []

      for (key, value) in feature_map:
        if value.get('name'):
          feature_names.append({
            'feature': value.get('name'),
            'type': feature_type,
            'id': key
          })
          continue

        match = id_pattern.match(key)
        if match:
          feature_names.append({
            'feature': '',
            'type': feature_type,
            'id': match.group(1)
          })
          continue
        
        feature_names.append({
          'feature': key,
          'type': feature_type,
          'id': ''
        })

      return feature_names
    except:
      return []

  id_pattern = re.compile(r'^Feature_(\d+)$')

  return get_feature_names(blink_features.get('Features'), 'default') + \
      get_feature_names(blink_features.get('CSSFeatures'), 'css') + \
      get_feature_names(blink_features.get('AnimatedCSSFeatures'), 'animated-css')


def get_technologies(page):
  """Parses the technologies from a page."""

  if not page:
    return

  app_names = page.get('_detected_apps', {})
  categories = page.get('_detected', {})

  # When there are no detected apps, it appears as an empty array.
  if isinstance(app_names, list):
    app_names = {}
    categories = {}

  technologies = {}
  app_map = {}
  for app, info_list in app_names.items():
    if not info_list:
      continue

    # There may be multiple info values. Add each to the map.
    for info in info_list.split(','):
      app_id = '%s %s' % (app, info) if len(info) > 0 else app
      app_map[app_id] = app

  for category, apps in categories.items():
    for app_id in apps.split(','):
      app = app_map.get(app_id)
      info = ''
      if app == None:
        app = app_id
      else:
        info = app_id[len(app):].strip()

      technologies[app] = technologies.get(app, {
        'technology': app,
        'info': [],
        'categories': []
      })
      
      technologies.get(app).get('info').append(info)
      if category not in technologies.get(app).get('categories'):
        technologies.get(app).get('categories').append(category)

  return list(technologies.values())


def get_lighthouse_reports(har):
  """Parses Lighthouse results from a HAR object."""

  if not har:
    return

  report = har.get('_lighthouse')

  if not report:
    return

  # Omit large UGC.
  report.get('audits').get('screenshot-thumbnails', {}).get('details', {}).pop('items', None)

  try:
    report_json = to_json(report)
  except:
    logging.warning('Skipping Lighthouse report: unable to stringify as JSON.')
    return

  report_size = len(report_json)
  if report_size > MAX_CONTENT_SIZE:
    logging.warning('Skipping Lighthouse report: Report size (%s) exceeded maximum content size of %s bytes.' % (report_size, MAX_CONTENT_SIZE))
    return

  return report_json


def to_json(obj):
  """Returns a JSON representation of the object.

  This method attempts to mirror the output of the
  legacy Java Dataflow pipeline. For the most part,
  the default `json.dumps` config does the trick,
  but there are a few settings to make it more consistent:

  - Omit whitespace between properties
  - Do not escape non-ASCII characters (preserve UTF-8)

  One difference between this Python implementation and the
  Java implementation is the way long numbers are handled.
  A Python-serialized JSON string might look like this:

    "timestamp":1551686646079.9998

  while the Java-serialized string uses scientific notation:

    "timestamp":1.5516866460799998E12

  Out of a sample of 200 actual request objects, this was
  the only difference between implementations. This can be
  considered an improvement.
  """

  if not obj:
    raise ValueError

  return json.dumps(obj, separators=(',', ':'), ensure_ascii=False)


def from_json(str):
  """Returns an object from the JSON representation."""

  try:
    return json.loads(str)
  except Exception as e:
    logging.error('Unable to parse JSON object "%s...": %s' % (str[:50], e))
    return


def get_gcs_dir(release):
  """Formats a release string into a gs:// directory."""

  return 'gs://httparchive/%s/' % release


def run(argv=None):
  """Constructs and runs the BigQuery import pipeline."""
  parser = argparse.ArgumentParser()
  parser.add_argument(
      '--input',
      required=True,
      help='Input Cloud Storage directory to process.')
  known_args, pipeline_args = parser.parse_known_args(argv)
  pipeline_options = PipelineOptions(pipeline_args)
  pipeline_options.view_as(SetupOptions).save_main_session = True


  with beam.Pipeline(options=pipeline_options) as p:
    gcs_dir = get_gcs_dir(known_args.input)

    hars = (p
      | beam.Create([gcs_dir])
      | beam.io.ReadAllFromText()
      | 'MapJSON' >> beam.Map(from_json))

    (hars
      | 'MapPages' >> beam.FlatMap(get_page)
      | 'WritePages' >> beam.io.WriteToBigQuery(
        'httparchive:all.pages',
        write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,
        create_disposition=beam.io.BigQueryDisposition.CREATE_NEVER))


if __name__ == '__main__':
  logging.getLogger().setLevel(logging.INFO)
  run()
