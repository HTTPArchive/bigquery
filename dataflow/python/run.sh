# Omit the runner option to run the pipeline locally.
#--runner=DataflowRunner \
python bigquery_import.py \
  --project=httparchive \
  --temp_location=gs://httparchive/dataflow/temp \
	--staging_location=gs://httparchive/dataflow/staging \
	--input android-Mar_24_2020