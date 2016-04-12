"""A easylist classifier."""

from __future__ import absolute_import
from adblockparser import AdblockRules

import argparse
import logging
import re2 as re

import google.cloud.dataflow as df

class EasylistClassifyDoFn(df.DoFn):
  def process(self, *args):
    row, classifiers = args[0].element, args[1]
    row['type'] = ''

    for (name, classifier) in classifiers.items():
      # TODO: add script initiator check
      if classifier.should_block(row['url'], {
                  'domain': row['domain'],
                  'third-party': row['third_party']
                }):
        row['type'] = name
        print row
        break

    del row['domain']
    del row['third_party']
    yield row

def run(argv=None):
  parser = argparse.ArgumentParser()
  parser.add_argument('--input',
                      dest='input',
                      required=True,
                      help='BigQuery request input table.')
  parser.add_argument('--output',
                      dest='output',
                      help='BigQuery output table.')
  known_args, pipeline_args = parser.parse_known_args(argv)

  output_table = '%s' % known_args.output
  input_query = """
    SELECT
      page, url,
      DOMAIN(page) as domain,
      IF (DOMAIN(page) == DOMAIN(url), false, true) AS third_party,
    FROM [%s]
  """ % known_args.input

  classifiers = {}
  for file in ['ad', 'tracker', 'social']:
    rules = [line.rstrip('\n') for line in open('local/'+file+'.txt')]
    classifier = AdblockRules(rules,
                    supported_options=['domain', 'third-party'],
                    skip_unsupported_rules=False, use_re2=True)
    del rules
    classifiers[file] = classifier

  p = df.Pipeline(argv=pipeline_args)

  (p
  | df.Read('read', df.io.BigQuerySource(query=input_query))
  | df.ParDo('classify', EasylistClassifyDoFn(), classifiers)
  # | df.io.Write('write', df.io.TextFileSink('out')))
  | df.Write('write', df.io.BigQuerySink(
      output_table,
      schema='page:STRING, url:STRING, type:STRING',
      create_disposition=df.io.BigQueryDisposition.CREATE_IF_NEEDED,
      write_disposition=df.io.BigQueryDisposition.WRITE_TRUNCATE)))

  p.run()

if __name__ == '__main__':
  logging.getLogger().setLevel(logging.INFO)
  run()
