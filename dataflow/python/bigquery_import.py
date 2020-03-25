#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

"""A word-counting workflow."""

# pytype: skip-file

from __future__ import absolute_import

import argparse
import json
import logging

import apache_beam as beam
from apache_beam.io.gcp.internal.clients import bigquery


def get_url(har):
  url = har.get('log').get('pages')[0].get('_URL')
  return {'url': url}


class Test1(beam.DoFn):
  def process(self, har):
    table_spec = bigquery.TableReference(
      projectId='httparchive',
      datasetId='scratchspace',
      tableId='dataflow_test1')

    table_schema = 'url:STRING'

    (har
      | beam.FlatMap(get_url)
      | 'BigQueryImport1' >> beam.io.WriteToBigQuery(
        table_spec,
        schema=table_schema,
        write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,
        create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED))

    return []


class Test2(beam.DoFn):
  def process(self, har):
    table_spec = bigquery.TableReference(
      projectId='httparchive',
      datasetId='scratchspace',
      tableId='dataflow_test2')

    table_schema = 'url:STRING'

    (har
      | beam.FlatMap(get_url)
      | 'BigQueryImport2' >> beam.io.WriteToBigQuery(
        table_spec,
        schema=table_schema,
        write_disposition=beam.io.BigQueryDisposition.WRITE_APPEND,
        create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED))

    return []


def get_gcs_uri(release):
  """Formats a release string into a gs:// file glob."""

  return 'gs://httparchive/%s/*.har.gz' % release


def run(argv=None):
  """Constructs and runs the BigQuery import pipeline."""
  parser = argparse.ArgumentParser()
  parser.add_argument(
      '--input',
      required=True,
      help='Input Cloud Storage directory to process.')
  known_args, pipeline_args = parser.parse_known_args(argv)


  with beam.Pipeline(argv=pipeline_args) as p:
    har = (p
      | beam.Create(['{"url": "test1", "foo": "abc"}', '{"url": "test2", "foo": "def"}'])
      | beam.Map(json.loads))

    (har
      | beam.Map(lambda har: {'url': har.get('url')})
      | 'Write1' >> beam.io.WriteToBigQuery(
        'httparchive:scratchspace.dataflow1',
        schema='url:STRING',
        write_disposition=beam.io.BigQueryDisposition.WRITE_TRUNCATE,
        create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED))

    (har
      | beam.Map(lambda har: {'foo': har.get('foo')})
      | 'Write2' >> beam.io.WriteToBigQuery(
        'httparchive:scratchspace.dataflow2',
        schema='foo:STRING',
        write_disposition=beam.io.BigQueryDisposition.WRITE_TRUNCATE,
        create_disposition=beam.io.BigQueryDisposition.CREATE_IF_NEEDED))
'''
    gcs_uri = get_gcs_uri(known_args.input)

    (p
      | 'read' >> beam.io.ReadFromText(gcs_uri)
      | 'ParseHAR' >> beam.Map(json.loads)
      | 'Test1' >> beam.ParDo(Test1())
      | 'Test2' >> beam.ParDo(Test2()))
'''


if __name__ == '__main__':
  logging.getLogger().setLevel(logging.INFO)
  run()