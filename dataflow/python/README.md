# HTTP Archive Python Dataflow

## Installation

Follow the [Quickstart using Python](https://cloud.google.com/dataflow/docs/quickstarts/quickstart-python#before-you-begin) guide.

1. Create and activate a Python 3 `virtualenv`:

  ```
  python -m virtualenv --python=python3 --clear env
  source env/bin/activate
  ```

2. Install dependencies:

  ```
  pip install -r requirements.txt
  ```

3. Create a service account key, save it to `credentials/cert.json`, and set the environment variable:

```
export GOOGLE_APPLICATION_CREDENTIALS="./credentials/auth.json"
```

This needs to be reset during the startup of every shell.

## Running the pipeline

1. Activate the Python virtual environment:

  ```
  source env/bin/activate
  ```

2. Run `bigquery_import.py`:

  ```
python bigquery_import.py \
  --runner=DataflowRunner \
  --project=httparchive \
  --temp_location=gs://httparchive/dataflow/temp \
  --staging_location=gs://httparchive/dataflow/staging \
  --region=us-west1 \
  --machine_type=n1-standard-32 \
  --input=android-Dec_1_2020 \
  --worker_disk_type=compute.googleapis.com/projects//zones//diskTypes/pd-ssd \
  --experiment=use_beam_bq_sink
  ```

  The `--runner=DataflowRunner` option forces the pipeline to run in the cloud using Dataflow. To run locally, omit this option. Be aware that crawls consume TB of disk space, so only run locally using subsetted input datasets. To create a subset dataset, copy a few HAR files on GCS to a new directory.

3. Decativate the virtual environment:

  ```
  deactivate
  ```
