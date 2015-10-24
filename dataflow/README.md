# Loading data

```
mvn exec:java -Dexec.mainClass=com.httparchive.dataflow.BigQueryImport -Dexec.args="--project=httparchive --stagingLocation=gs://httparchive/dataflow/staging --runner=BlockingDataflowPipelineRunner --input=desktop-Oct_15_2015 --workerMachineType=n1-standard-4"
```
