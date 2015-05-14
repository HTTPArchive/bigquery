package com.httparchive.dataflow;

import com.fasterxml.jackson.databind.JsonNode;
import com.google.api.services.bigquery.model.TableFieldSchema;
import com.google.api.services.bigquery.model.TableRow;
import com.google.api.services.bigquery.model.TableSchema;

import com.google.cloud.dataflow.sdk.Pipeline;
import com.google.cloud.dataflow.sdk.io.TextIO;
import com.google.cloud.dataflow.sdk.options.Default;
import com.google.cloud.dataflow.sdk.options.Description;
import com.google.cloud.dataflow.sdk.options.PipelineOptions;
import com.google.cloud.dataflow.sdk.options.PipelineOptionsFactory;
import com.google.cloud.dataflow.sdk.options.Validation;
import com.google.cloud.dataflow.sdk.transforms.DoFn;
import com.google.cloud.dataflow.sdk.transforms.ParDo;
import com.google.cloud.dataflow.sdk.values.PCollection;
import com.google.cloud.dataflow.sdk.io.BigQueryIO;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.google.cloud.dataflow.sdk.options.DataflowPipelineOptions;
import com.google.cloud.dataflow.sdk.options.DataflowPipelineWorkerPoolOptions;
import com.google.cloud.dataflow.sdk.util.gcsfs.GcsPath;
import com.google.cloud.dataflow.sdk.values.PCollectionTuple;
import com.google.cloud.dataflow.sdk.values.TupleTag;
import com.google.cloud.dataflow.sdk.values.TupleTagList;
import java.io.IOException;

import java.util.ArrayList;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class BigQueryImport {

    private static final Logger LOG = LoggerFactory.getLogger(BigQueryImport.class);
    public static final TupleTag<TableRow> pagesTag = new TupleTag<TableRow>() {
    };
    public static final TupleTag<TableRow> entriesTag = new TupleTag<TableRow>() {
    };

    static class DataExtractorFn extends DoFn<JsonNode, TableRow> {

        private static final ObjectMapper MAPPER
                = new ObjectMapper().disable(SerializationFeature.FAIL_ON_EMPTY_BEANS);

        @Override
        public void processElement(ProcessContext c) {
            try {
                JsonNode har = c.element();
                JsonNode data = har.get("log");
                JsonNode pages = data.get("pages");

                if (pages.size() == 0) {
                    LOG.error("Empty HAR, skipping: {}", MAPPER.writeValueAsString(har));
                    return;
                }

                JsonNode page = pages.get(0);
                String pageUrl = page.get("_URL").textValue();
                ObjectNode object = (ObjectNode) page;

                String pageJSON = MAPPER.writeValueAsString(object);

                TableRow pageRow = new TableRow()
                        .set("url", pageUrl)
                        .set("payload", pageJSON);
                c.output(pageRow);

                JsonNode entries = data.get("entries");
                for (final JsonNode req : entries) {
                    String resourceUrl = req.get("_full_url").textValue();
                    String reqJSON = MAPPER.writeValueAsString(req);
                    TableRow request = new TableRow()
                            .set("page", pageUrl)
                            .set("url", resourceUrl)
                            .set("payload", reqJSON);
                    c.sideOutput(entriesTag, request);
                }

            } catch (IOException e) {
                LOG.error("Failed to process HAR", e);
            }
        }
    }

    public static interface Options extends PipelineOptions {

        @Description("GCS folder containing HAR files to read from")
        @Validation.Required
        String getInput();
        void setInput(String value);

        @Description("Dataset to write to: <project_id>:<dataset_id>")
        @Default.String("httparchive:har")
        @Validation.Required
        String getOutput();
        void setOutput(String value);
    }

    // Input: mobile-Nov_15_2014
    // Output: gs://httparchive/mobile_nov_15_2014/*.har.gz
    private static String getHarBucket(Options options) {
        return GcsPath.fromUri("gs://httparchive/")
                .resolve(options.getInput() + "/")
                .resolve("*.har.gz")
                .toString();
    }

    // <project>:<dataset>.<table>
    // Input: mobile-Nov_15_2014
    // Output: httparchive:har.mobile_nov_15_2014
    private static String getBigQueryOutput(Options options, String trailer) {
        return options.getOutput() + "."
                + options.getInput().replaceFirst("-", "_").toLowerCase()
                + "_" + trailer;
    }

    public static void main(String[] args) {
        Options options = PipelineOptionsFactory.fromArgs(args)
                .withValidation().as(Options.class);

        DataflowPipelineOptions pipelineOptions
                = options.as(DataflowPipelineOptions.class);
        pipelineOptions.setNumWorkers(10);
        pipelineOptions.setMaxNumWorkers(20);
        pipelineOptions.setAutoscalingAlgorithm(
                DataflowPipelineWorkerPoolOptions.AutoscalingAlgorithmType.BASIC);

        Pipeline p = Pipeline.create(pipelineOptions);

        PCollectionTuple results = p.apply(TextIO.Read
                .named("read-har")
                .from(getHarBucket(options))
                .withCompressionType(TextIO.CompressionType.GZIP)
                .withCoder(HarJsonCoder.of()))
                .apply(ParDo
                        .withOutputTags(
                                BigQueryImport.pagesTag,
                                TupleTagList.of(BigQueryImport.entriesTag))
                        .of(new DataExtractorFn())
                );

        List<TableFieldSchema> page = new ArrayList<>();
        page.add(new TableFieldSchema().setName("url").setType("STRING")
                .setDescription("URL of the parent document"));
        page.add(new TableFieldSchema().setName("payload").setType("STRING")
                .setDescription("JSON-encoded parent document HAR data"));
        TableSchema pageSchema = new TableSchema().setFields(page);

        PCollection<TableRow> pages = results.get(BigQueryImport.pagesTag);
        pages.apply(BigQueryIO.Write
                .named("write-pages")
                .to(getBigQueryOutput(options, "pages"))
                .withSchema(pageSchema)
                .withCreateDisposition(BigQueryIO.Write.CreateDisposition.CREATE_IF_NEEDED)
                .withWriteDisposition(BigQueryIO.Write.WriteDisposition.WRITE_TRUNCATE));

        List<TableFieldSchema> request = new ArrayList<>();
        request.add(new TableFieldSchema().setName("page").setType("STRING")
                .setDescription("URL of the parent document"));
        request.add(new TableFieldSchema().setName("url").setType("STRING")
                .setDescription("URL of the subresource"));
        request.add(new TableFieldSchema().setName("payload").setType("STRING")
                .setDescription("JSON-encoded subresource HAR data"));
        TableSchema reqSchema = new TableSchema().setFields(request);

        PCollection<TableRow> entries = results.get(BigQueryImport.entriesTag);
        entries.apply(BigQueryIO.Write
                .named("write-entries")
                .to(getBigQueryOutput(options, "requests"))
                .withSchema(reqSchema)
                .withCreateDisposition(BigQueryIO.Write.CreateDisposition.CREATE_IF_NEEDED)
                .withWriteDisposition(BigQueryIO.Write.WriteDisposition.WRITE_TRUNCATE));

        p.run();
    }
}
