# Omit the runner option to run the pipeline locally.
#--runner=DataflowRunner \
python bigquery_import.py \
  --runner=DataflowRunner \
  --project=httparchive \
  --temp_location=gs://httparchive/dataflow/temp \
  --staging_location=gs://httparchive/dataflow/staging \
  --region=us-central1 \
  --machine_type=n1-standard-4 \
  --input android-Mar_1_2020