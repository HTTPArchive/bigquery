"""HTTP Archive dataflow pipeline for generating HAR data on BigQuery."""

from __future__ import absolute_import

import argparse
from copy import deepcopy
from datetime import datetime
import json
import logging
import re

import apache_beam as beam
import apache_beam.io.gcp.gcsio as gcsio
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.options.pipeline_options import SetupOptions


# BigQuery can handle rows up to 100 MB.
MAX_CONTENT_SIZE = 100 * 1024 * 1024


def get_page(har):
  """Parses the page from a HAR object."""

  page = har.get('log').get('pages')[0]
  url = page.get('_URL')

  return {
    'url': url,
    'payload': to_json(page)
  }


def get_page_url(har):
  """Parses the page URL from a HAR object."""

  return get_page(har).get('url')


def get_requests(har):
  """Parses the requests from a HAR object."""

  page_url = get_page_url(har)
  requests = har.get('log').get('entries')

  return [{
    'page': page_url,
    'url': request.get('_full_url'),
    'payload': to_json(trim_request(request))
  } for request in requests]


def trim_request(request):
  """Removes redundant fields from the request object."""

  # Make a copy first so the response body can be used later.
  request = deepcopy(request)
  request.get('response').get('content').pop('text', None)
  return request


def get_response_bodies(har):
  """Parses response bodies from a HAR object."""

  page_url = get_page_url(har)
  requests = har.get('log').get('entries')

  response_bodies = []

  for request in requests:
    request_url = request.get('_full_url')
    body = request.get('response').get('content').get('text', '')

    response_bodies.append({
      'page': page_url,
      'url': request_url,
      'body': body[:MAX_CONTENT_SIZE],
      'truncated': len(body) > MAX_CONTENT_SIZE
    })

  return response_bodies


def get_technologies(har):
  """Parses the technologies from a HAR object."""
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

  report = har.get('_lighthouse')

  if not report:
    return

  page_url = get_page_url(har)

  # Omit large UGC.
  report.get('audits').get('screenshot-thumbnails', {}).get('details', {}).pop('items', None)

  # FIXME: Handle invalid JSON.
  report_json = to_json(report)
  if len(report_json) > MAX_CONTENT_SIZE:
    logging.info('Skipping Lighthouse report for "%s": exceeded maximum content size of %s bytes.' % (page_url, MAX_CONTENT_SIZE))
    return

  return {
    'url': page_url,
    'report': report_json
  }


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

  return json.dumps(obj, separators=(',', ':'), ensure_ascii=False)


def get_gcs_dir(release):
  """Formats a release string into a gs:// directory."""

  return 'gs://httparchive/%s/' % release


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
  #date_string = date_obj.strftime('%Y_%m_%d') # 2020_03_01
  # TODO(rviscomi): This is just for debugging.
  date_string = date_obj.strftime('%Y_%m_15') # 2020_03_15

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
      | beam.Map(json.loads))

    (hars
      | 'MapPages' >> beam.Map(get_page)
      | 'WritePages' >> beam.io.WriteToBigQuery(
        get_bigquery_uri(known_args.input, 'pages'),
        schema='url:STRING, payload:STRING',
        write_disposition=beam.io.BigQueryDisposition.WRITE_TRUNCATE,
        create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED))

    (hars
      | 'MapRequests' >> beam.FlatMap(get_requests)
      | 'WriteRequests' >> beam.io.WriteToBigQuery(
        get_bigquery_uri(known_args.input, 'requests'),
        schema='page:STRING, url:STRING, payload:STRING',
        write_disposition=beam.io.BigQueryDisposition.WRITE_TRUNCATE,
        create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED))

    (hars
      | 'MapResponseBodies' >> beam.FlatMap(get_response_bodies)
      | 'WriteResponseBodies' >> beam.io.WriteToBigQuery(
        get_bigquery_uri(known_args.input, 'response_bodies'),
        schema='page:STRING, url:STRING, body:STRING, truncated:BOOLEAN',
        write_disposition=beam.io.BigQueryDisposition.WRITE_TRUNCATE,
        create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED))

    (hars
      | 'MapTechnologies' >> beam.FlatMap(get_technologies)
      | 'WriteTechnologies' >> beam.io.WriteToBigQuery(
        get_bigquery_uri(known_args.input, 'technologies'),
        schema='url:STRING, category:STRING, app:STRING, info:STRING',
        write_disposition=beam.io.BigQueryDisposition.WRITE_TRUNCATE,
        create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED))

    # Skip Lighthouse for desktop HARs.
    if known_args.input.startswith('android'):
      (hars
        | 'MapLighthouseReports' >> beam.Map(get_lighthouse_reports)
        | 'WriteLighthouseReports' >> beam.io.WriteToBigQuery(
          get_bigquery_uri(known_args.input, 'lighthouse'),
          schema='url:STRING, report:STRING',
          write_disposition=beam.io.BigQueryDisposition.WRITE_TRUNCATE,
          create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED))


if __name__ == '__main__':
  logging.getLogger().setLevel(logging.INFO)
  run()