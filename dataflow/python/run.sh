# Omit the runner option to run the pipeline locally.
#--runner=DataflowRunner \
python bigquery_import.py \
  --runner=DataflowRunner \
  --project=httparchive \
  --temp_location=gs://httparchive/dataflow/temp \
  --staging_location=gs://httparchive/dataflow/staging \
  --region=us-west1 \
  --machine_type=n1-standard-32 \
  --input=android-Jul_1_2021 \
  --worker_disk_type=compute.googleapis.com/projects//zones//diskTypes/pd-ssd
