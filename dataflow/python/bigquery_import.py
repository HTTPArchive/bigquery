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
MAX_CONTENT_SIZE = 2 * 1024 * 1024
# Number of times to partition the requests tables.
NUM_PARTITIONS = 4


def get_page(har):
  """Parses the page from a HAR object."""

  if not har:
    return

  page = har.get('log').get('pages')[0]
  url = page.get('_URL')

  metadata = page.get('_metadata')
  if metadata:
    # The page URL from metadata is more accurate.
    # See https://github.com/HTTPArchive/data-pipeline/issues/48
    url = metadata.get('tested_url', url)

  try:
    payload_json = to_json(page)
  except:
    logging.warning('Skipping pages payload for "%s": unable to stringify as JSON.' % url)
    return

  payload_size = len(payload_json)
  if payload_size > MAX_CONTENT_SIZE:
    logging.warning('Skipping pages payload for "%s": payload size (%s) exceeds the maximum content size of %s bytes.' % (url, payload_size, MAX_CONTENT_SIZE))
    return

  return [{
    'url': url,
    'payload': payload_json
  }]


def get_page_url(har):
  """Parses the page URL from a HAR object."""

  page = get_page(har)

  if not page:
    logging.warning('Unable to get URL from page (see preceding warning).')
    return

  return page[0].get('url')


def partition_step(fn, har, index):
  """Partitions functions across multiple concurrent steps."""

  logging.info(f'partitioning step {fn}, index {index}')

  if not har:
    logging.warning('Unable to partition step, null HAR.')
    return

  page_url = get_page_url(har)

  if not page_url:
    logging.warning('Skipping HAR: unable to get page URL (see preceding warning).')
    return

  hash = hash_url(page_url)
  if hash % NUM_PARTITIONS != index:
    logging.info(f'Skipping partition. {hash} % {NUM_PARTITIONS} != {index}')
    return
  
  return fn(har)


def get_requests(har):
  """Parses the requests from a HAR object."""

  if not har:
    return

  page_url = get_page_url(har)

  if not page_url:
    # The page_url field indirectly depends on the get_page function.
    # If the page data is unavailable for whatever reason, skip its requests.
    logging.warning('Skipping requests payload: unable to get page URL (see preceding warning).')
    return

  entries = har.get('log').get('entries')

  requests = []

  for request in entries:

    request_url = request.get('_full_url')

    try:
      payload = to_json(trim_request(request))
    except:
      logging.warning('Skipping requests payload for "%s": unable to stringify as JSON.' % request_url)
      continue

    payload_size = len(payload)
    if payload_size > MAX_CONTENT_SIZE:
      logging.warning('Skipping requests payload for "%s": payload size (%s) exceeded maximum content size of %s bytes.' % (request_url, payload_size, MAX_CONTENT_SIZE))
      continue

    requests.append({
      'page': page_url,
      'url': request_url,
      'payload': payload
    })

  return requests


def trim_request(request):
  """Removes redundant fields from the request object."""

  # Make a copy first so the response body can be used later.
  request = deepcopy(request)
  request.get('response').get('content').pop('text', None)
  return request


def hash_url(url):
  """Hashes a given URL to a process-stable integer value."""
  return int(sha256(url.encode('utf-8')).hexdigest(), 16)


def get_response_bodies(har):
  """Parses response bodies from a HAR object."""

  page_url = get_page_url(har)
  requests = har.get('log').get('entries')

  response_bodies = []

  for request in requests:
    request_url = request.get('_full_url')
    body = None
    if request.get('response') and request.get('response').get('content'):
        body = request.get('response').get('content').get('text', None)

    if body == None:
      continue

    truncated = len(body) > MAX_CONTENT_SIZE
    if truncated:
      logging.warning('Truncating response body for "%s". Response body size %s exceeds limit %s.' % (request_url, len(body), MAX_CONTENT_SIZE))

    response_bodies.append({
      'page': page_url,
      'url': request_url,
      'body': body[:MAX_CONTENT_SIZE],
      'truncated': truncated
    })

  return response_bodies


def get_technologies(har):
  """Parses the technologies from a HAR object."""

  if not har:
    return

  page = har.get('log').get('pages')[0]
  page_url = page.get('_URL')
  app_names = page.get('_detected_apps', {})
  categories = page.get('_detected', {})

  # When there are no detected apps, it appears as an empty array.
  if isinstance(app_names, list):
    app_names = {}
    categories = {}

  app_map = {}
  app_list = []
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
      app_list.append({
        'url': page_url,
        'category': category,
        'app': app,
        'info': info
      })

  return app_list


def get_lighthouse_reports(har):
  """Parses Lighthouse results from a HAR object."""

  if not har:
    return

  report = har.get('_lighthouse')

  if not report:
    return

  page_url = get_page_url(har)

  if not page_url:
    logging.warning('Skipping lighthouse report: unable to get page URL (see preceding warning).')
    return

  # Omit large UGC.
  report.get('audits').get('screenshot-thumbnails', {}).get('details', {}).pop('items', None)

  try:
    report_json = to_json(report)
  except:
    logging.warning('Skipping Lighthouse report for "%s": unable to stringify as JSON.' % page_url)
    return

  report_size = len(report_json)
  if report_size > MAX_CONTENT_SIZE:
    logging.warning('Skipping Lighthouse report for "%s": Report size (%s) exceeded maximum content size of %s bytes.' % (page_url, report_size, MAX_CONTENT_SIZE))
    return

  return [{
    'url': page_url,
    'report': report_json
  }]


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

  return 'gs://httparchive/crawls/%s/' % release


def gcs_list(gcs_dir):
  """Lists all files in a GCS directory."""
  gcs = gcsio.GcsIO()
  return gcs.list_prefix(gcs_dir)


def get_bigquery_uri(release, dataset):
  """Formats a release string into a BigQuery dataset/table."""

  client, date_string = release.split('-')

  if client == 'chrome':
    client = 'desktop'
  elif client == 'android':
    client = 'mobile'

  date_obj = datetime.strptime(date_string, '%b_%d_%Y') # Mar_01_2020
  date_string = date_obj.strftime('%Y_%m_%d') # 2020_03_01

  return 'httparchive:%s.%s_%s' % (dataset, date_string, client)


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

    for i in range(NUM_PARTITIONS):
      (hars
        | f'MapPages{i}' >> beam.FlatMap(
          (lambda i: lambda har: partition_step(get_page, har, i))(i))
        | f'WritePages{i}' >> beam.io.WriteToBigQuery(
          get_bigquery_uri(known_args.input, 'pages'),
          schema='url:STRING, payload:STRING',
          write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,
          create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED))

      (hars
        | f'MapTechnologies{i}' >> beam.FlatMap(
          (lambda i: lambda har: partition_step(get_technologies, har, i))(i))
        | f'WriteTechnologies{i}' >> beam.io.WriteToBigQuery(
          get_bigquery_uri(known_args.input, 'technologies'),
          schema='url:STRING, category:STRING, app:STRING, info:STRING',
          write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,
          create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED))

      (hars
        | f'MapLighthouseReports{i}' >> beam.FlatMap(
          (lambda i: lambda har: partition_step(get_lighthouse_reports, har, i))(i))
        | f'WriteLighthouseReports{i}' >> beam.io.WriteToBigQuery(
          get_bigquery_uri(known_args.input, 'lighthouse'),
          schema='url:STRING, report:STRING',
          write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,
          create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED))
      (hars
        | f'MapRequests{i}' >> beam.FlatMap(
          (lambda i: lambda har: partition_step(get_requests, har, i))(i))
        | f'WriteRequests{i}' >> beam.io.WriteToBigQuery(
          get_bigquery_uri(known_args.input, 'requests'),
          schema='page:STRING, url:STRING, payload:STRING',
          write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,
          create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED))

      (hars
        | f'MapResponseBodies{i}' >> beam.FlatMap(
          (lambda i: lambda har: partition_step(get_response_bodies, har, i))(i))
        | f'WriteResponseBodies{i}' >> beam.io.WriteToBigQuery(
          get_bigquery_uri(known_args.input, 'response_bodies'),
          schema='page:STRING, url:STRING, body:STRING, truncated:BOOLEAN',
          write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,
          create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED))


if __name__ == '__main__':
  logging.getLogger().setLevel(logging.INFO)
  run()
