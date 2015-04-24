# Loading data

```
mvn exec:java -Dexec.mainClass=com.httparchive.dataflow.BigQueryImport -Dexec.args="--project=httparchive --stagingLocation=gs://httparchive/dataflow/staging --runner=BlockingDataflowPipelineRunner --input=desktop-Apr_15_2015"
```
