# Loading data

```
mvn compile exec:java -Dexec.mainClass=com.httparchive.dataflow.BigQueryImport -Dexec.args="--project=httparchive --stagingLocation=gs://httparchive/dataflow/staging --runner=BlockingDataflowPipelineRunner --input=desktop-Oct_15_2015 --workerMachineType=n1-standard-4"
```

## Installing Java on Debian
- https://www.digitalocean.com/community/tutorials/how-to-manually-install-oracle-java-on-a-debian-or-ubuntu-vps
