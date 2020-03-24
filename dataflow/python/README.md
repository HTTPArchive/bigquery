# HTTP Archive Python Dataflow

## Installation

Follow the [Quickstart using Python](https://cloud.google.com/dataflow/docs/quickstarts/quickstart-python#before-you-begin) guide.

1. Create a Python 3 `virtualenv`:

  ```
  python -m virtualenv --python=python3 --clear env
  ```

2. Install dependencies:

  ```
  pip install -r requirements.txt
  ```

3. Create a service account key, save it to `credentials/cert.json`, and set the environment variable:

	```
	export GOOGLE_APPLICATION_CREDENTIALS="./credentials/auth.json"
	```