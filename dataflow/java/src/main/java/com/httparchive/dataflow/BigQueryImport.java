package com.httparchive.dataflow;

import com.fasterxml.jackson.databind.JsonNode;
import com.google.api.services.bigquery.model.TableFieldSchema;
import com.google.api.services.bigquery.model.TableRow;
import com.google.api.services.bigquery.model.TableSchema;

import com.google.cloud.dataflow.sdk.Pipeline;
import com.google.cloud.dataflow.sdk.options.Default;
import com.google.cloud.dataflow.sdk.options.Description;
import com.google.cloud.dataflow.sdk.options.PipelineOptions;
import com.google.cloud.dataflow.sdk.options.PipelineOptionsFactory;
import com.google.cloud.dataflow.sdk.options.Validation;
import com.google.cloud.dataflow.sdk.transforms.Create;
import com.google.cloud.dataflow.sdk.transforms.DoFn;
import com.google.cloud.dataflow.sdk.transforms.Flatten;
import com.google.cloud.dataflow.sdk.transforms.ParDo;
import com.google.cloud.dataflow.sdk.transforms.SerializableFunction;
import com.google.cloud.dataflow.sdk.transforms.Values;
import com.google.cloud.dataflow.sdk.transforms.WithKeys;
import com.google.cloud.dataflow.sdk.values.PCollection;
import com.google.cloud.dataflow.sdk.io.BigQueryIO;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.google.cloud.dataflow.sdk.options.DataflowPipelineOptions;
import com.google.cloud.dataflow.sdk.options.DataflowPipelineWorkerPoolOptions;
import com.google.cloud.dataflow.sdk.transforms.Aggregator;
import com.google.cloud.dataflow.sdk.transforms.Sum;
import com.google.cloud.dataflow.sdk.util.GcsUtil;
import com.google.cloud.dataflow.sdk.util.GcsUtil.GcsUtilFactory;
import com.google.cloud.dataflow.sdk.util.Reshuffle;
import com.google.cloud.dataflow.sdk.util.gcsfs.GcsPath;
import com.google.cloud.dataflow.sdk.values.PCollectionTuple;
import com.google.cloud.dataflow.sdk.values.TupleTag;
import com.google.cloud.dataflow.sdk.values.TupleTagList;
import java.io.BufferedInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.channels.Channels;
import java.nio.channels.SeekableByteChannel;
import java.text.ParseException;
import java.text.SimpleDateFormat;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.zip.ZipEntry;
import java.util.zip.ZipException;
import java.util.zip.GZIPInputStream;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class BigQueryImport {

    private static final Logger LOG = LoggerFactory.getLogger(BigQueryImport.class);
    public static final TupleTag<TableRow> PAGES_TAG = new TupleTag<TableRow>() {
    };
    public static final TupleTag<TableRow> ENTRIES_TAG = new TupleTag<TableRow>() {
    };
    public static final TupleTag<TableRow> BODIES_TAG = new TupleTag<TableRow>() {
    };
    public static final TupleTag<TableRow> LIGHTHOUSE_TAG = new TupleTag<TableRow>() {
    };
    public static final TupleTag<TableRow> APPS_TAG = new TupleTag<TableRow>() {
    };

    private static class Response {

        public String body;
        public boolean truncated;

        public Response(String b, boolean t) {
            this.body = b;
            this.truncated = t;
        }
    }

    static class DataExtractorFn extends DoFn<GcsPath, TableRow> {

        private static final Logger LOG
                = LoggerFactory.getLogger(DataExtractorFn.class);

        private static final ObjectMapper MAPPER
                = new ObjectMapper().disable(SerializationFeature.FAIL_ON_EMPTY_BEANS);

        private final Aggregator<Long, Long> withBody
                = createAggregator("withBody", new Sum.SumLongFn());

        private final Aggregator<Long, Long> truncatedBody
                = createAggregator("truncatedBody", new Sum.SumLongFn());

        private final Aggregator<Long, Long> skippedLighthouse
                = createAggregator("skippedLighthouse", new Sum.SumLongFn());

        private final Aggregator<Long, Long> skippedBody
                = createAggregator("skippedBody", new Sum.SumLongFn());

        // row limit is 100 MB
        private static final Integer MAX_CONTENT_SIZE = 100 * 1024 * 1024;

        public static Response truncateUTF8(String s, int maxBytes) {
            int b = 0;
            for (int i = 0; i < s.length(); i++) {
                char c = s.charAt(i);

                // ranges from http://en.wikipedia.org/wiki/UTF-8
                int skip = 0;
                int more;
                if (c <= 0x007f) {
                    more = 1;
                } else if (c <= 0x07FF) {
                    more = 2;
                } else if (c <= 0xd7ff) {
                    more = 3;
                } else if (c <= 0xDFFF) {
                    // surrogate area, consume next char as well
                    more = 4;
                    skip = 1;
                } else {
                    more = 3;
                }

                // Account for JSON escaping. Adapted from:
                // http://stackoverflow.com/a/16652683/510112
                switch (c) {
                    case '\\':
                    case '"':
                    case '/':
                        more += 2;
                        break;
                    case '\b':
                    case '\t':
                    case '\n':
                    case '\f':
                    case '\r':
                        more += 1;
                        break;
                    default:
                        if (c < ' ') {
                            String t = "000" + Integer.toHexString(c);
                            more += 3 + t.length();
                        }
                }

                if (b + more > maxBytes) {
                    return new Response(s.substring(0, i), true);
                }
                b += more;
                i += skip;
            }
            return new Response(s, false);
        }

        public byte[] unzipGcsFile(GcsPath zipFile, GcsUtil gcsUtil) throws IOException {
            // TODO (rviscomi): Investigate effects of using a larger buffer size on pipeline speed.
            byte[] buffer = new byte[1024];
            SeekableByteChannel seekableByteChannel = gcsUtil.open(zipFile);
            InputStream inputStream = Channels.newInputStream(seekableByteChannel);
            GZIPInputStream gzipInputStream = new GZIPInputStream(inputStream);
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();

            try {
                int len = 0;
                while ((len = gzipInputStream.read(buffer)) > 0) {
                    outputStream.write(buffer, 0, len);
                }
            } finally {
                gzipInputStream.close();
                outputStream.close();
            }

            return outputStream.toByteArray();
        }

        public JsonNode decodeHar(GcsPath harFile, GcsUtil gcsUtil) throws IOException {
            try {
                byte[] harBytes = unzipGcsFile(harFile, gcsUtil);
                return MAPPER.readTree(harBytes);
            } catch (IOException e) {
                LOG.error("Failed to decode HAR: {}, {}", e, harFile.toString());
                throw e;
            }
        }

        @Override
        public void processElement(ProcessContext c) {
            try {
                GcsPath harFile = c.element();
                GcsUtilFactory factory = new GcsUtilFactory();
                GcsUtil gcsUtil = factory.create(c.getPipelineOptions());
                JsonNode har = decodeHar(harFile, gcsUtil);
                JsonNode data = har.get("log");
                JsonNode pages = data.get("pages");
                JsonNode lighthouse = har.get("_lighthouse");

                if (pages.size() == 0) {
                    LOG.error("Empty HAR, skipping: {}", MAPPER.writeValueAsString(har));
                    return;
                }

                JsonNode page = pages.get(0);
                String pageUrl;
                if (page.has("_URL")) {
                    pageUrl = page.get("_URL").textValue();
                } else {
                    LOG.error("Missing _URL, skipping: {}", MAPPER.writeValueAsString(har));
                    return;
                }

                ObjectNode object = (ObjectNode) page;
                String pageJSON = MAPPER.writeValueAsString(object);

                TableRow pageRow = new TableRow()
                        .set("url", pageUrl)
                        .set("payload", pageJSON);
                c.output(pageRow);


                if (page.has("_detected") &&
                        page.has("_detected_apps") &&
                        page.get("_detected").isObject() &&
                        page.get("_detected_apps").isObject()) {
                    // Map the category detections to the app/info values.
                    Map<String,String> appMap = new HashMap<String,String>();
                    ObjectNode appNames = (ObjectNode) page.get("_detected_apps");
                    Iterator<String> appIterator = appNames.fieldNames();
                    while (appIterator.hasNext()) {
                        String app = appIterator.next();
                        // There may be multiple info values. Add each to the map.
                        String[] infoList = appNames.get(app).asText().split(",");
                        for (String info : infoList) {
                            String appId = info.length() > 0 ? app + " " + info : app;
                            appMap.put(appId, app);
                        }
                    }

                    ObjectNode categories = (ObjectNode) page.get("_detected");
                    Iterator<String> categoryIterator = categories.fieldNames();
                    while (categoryIterator.hasNext()) {
                        String category = categoryIterator.next();
                        String[] apps = categories.get(category).asText().split(",");
                        for (String appId : apps) {
                            String app = appMap.get(appId);
                            String info = "";
                            if (app == null) {
                                app = appId;
                            } else {
                                info = appId.substring(app.length()).trim();
                            }
                            TableRow appRow = new TableRow()
                                .set("url", pageUrl)
                                .set("category", category)
                                .set("app", app)
                                .set("info", info);
                            c.sideOutput(APPS_TAG, appRow);
                        }
                    }
                }


                if (lighthouse != null && lighthouse.isObject()) {
                    // Omit image data.
                    object = (ObjectNode) lighthouse.get("audits").get("screenshot-thumbnails");
                    if (object != null) {
                        object = (ObjectNode) object.get("details");
                        if (object != null) {
                            object.remove("items");
                        }
                    }

                    String lighthouseJSON = MAPPER.writeValueAsString(lighthouse);
                    TableRow lighthouseRow = new TableRow()
                            .set("url", pageUrl)
                            .set("report", lighthouseJSON);

                    String lighthouseRowJSON = MAPPER.writeValueAsString(lighthouseRow);
                    Integer lighthouseRowSize = lighthouseRowJSON.getBytes("UTF-8").length + pageUrl.getBytes("UTF-8").length;
                    if (lighthouseRowSize > MAX_CONTENT_SIZE) {
                        skippedLighthouse.addValue(1L);
                    } else {
                        c.sideOutput(LIGHTHOUSE_TAG, lighthouseRow);
                    }
                }

                JsonNode entries = data.get("entries");
                for (final JsonNode r : entries) {
                    ObjectNode req = (ObjectNode) r.deepCopy();

                    String resourceUrl;
                    if (req.has("_full_url")) {
                        resourceUrl = req.get("_full_url").textValue();
                    } else if (req.has("url")) {
                        resourceUrl = req.get("url").textValue();
                    } else {
                        resourceUrl = "";
                    }

                    ObjectNode resp = (ObjectNode) req.get("response");
                    ObjectNode content = (ObjectNode) resp.get("content");

                    if (content != null && content.has("text")) {
                        withBody.addValue(1L);

                        JsonNode text = content.remove("text");
                        int maxSize = MAX_CONTENT_SIZE
                                - pageUrl.getBytes("UTF-8").length
                                - resourceUrl.getBytes("UTF-8").length
                                - 128;

                        Response rsp = truncateUTF8(text.textValue(), maxSize);
                        if (rsp.truncated) {
                            truncatedBody.addValue(1L);
                            LOG.warn("Truncated response: {} {}",
                                    resourceUrl, pageJSON);
                        }

                        TableRow body = new TableRow()
                                .set("page", pageUrl)
                                .set("url", resourceUrl)
                                .set("body", rsp.body)
                                .set("truncated", rsp.truncated);

                        String bodyJSON = MAPPER.writeValueAsString(body);
                        Integer recordSize = bodyJSON.getBytes("UTF-8").length;

                        if (recordSize > MAX_CONTENT_SIZE) {
                            skippedBody.addValue(1L);
                            LOG.error("Body too large, skipping: {} {} {} {}",
                                    recordSize, pageUrl,
                                    resourceUrl, pageJSON);
                            continue;
                        } else {
                            c.sideOutput(BODIES_TAG, body);
                        }
                    }

                    String reqJSON = MAPPER.writeValueAsString(req);
                    TableRow request = new TableRow()
                            .set("page", pageUrl)
                            .set("url", resourceUrl)
                            .set("payload", reqJSON);
                    c.sideOutput(ENTRIES_TAG, request);
                }

            } catch (IOException e) {
                LOG.error("Failed to process HAR", e);
            }
        }
    }

    static class ExpandGlobFn extends DoFn<GcsPath, List<GcsPath>> {

        private static final Logger LOG
                = LoggerFactory.getLogger(ExpandGlobFn.class);

        @Override
        public void processElement(ProcessContext c) {
            GcsUtilFactory factory = new GcsUtilFactory();
            GcsUtil gcsUtil = factory.create(c.getPipelineOptions());
            GcsPath harGlob = c.element();
            try {
                List<GcsPath> harFiles = gcsUtil.expand(harGlob);
                c.output(harFiles);
            } catch (IOException e) {
                LOG.error("Failed to expand GCS har glob", e);
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
    private static GcsPath getHarBucket(Options options) {
        return GcsPath.fromUri("gs://httparchive/")
                .resolve(options.getInput() + "/")
                .resolve("*.har.gz");
    }

    // Input: chrome-Nov_15_2014
    // Output: httparchive:dataset.YYYY_MM_DD_client
    private static String getBigQueryOutput(Options options, String dataset) {
        String[] parts = options.getInput().split("-");
        String client = parts[0].equals("chrome") ? "desktop" : "mobile";
        String date = parts[1];

        SimpleDateFormat inputFormatter = new SimpleDateFormat("MMM_dd_yyyy");
        SimpleDateFormat outputFormatter = new SimpleDateFormat("yyyy_MM_dd");

        try {
            Date parsedDate = inputFormatter.parse(date);
            date = outputFormatter.format(parsedDate);
        } catch (ParseException e) {
            LOG.error("Failed to parse table date", e);
        }

        return dataset + "." // pages/requests/...
                + date + "_" // 2020_01_01_
                + client; // desktop/mobile
    }

    public static void main(String[] args) {
        Options options = PipelineOptionsFactory.fromArgs(args)
                .withValidation().as(Options.class);

        DataflowPipelineOptions pipelineOptions
                = options.as(DataflowPipelineOptions.class);
        pipelineOptions.setNumWorkers(20);
        pipelineOptions.setMaxNumWorkers(20);
        pipelineOptions.setAutoscalingAlgorithm(
                DataflowPipelineWorkerPoolOptions.AutoscalingAlgorithmType.NONE);

        Pipeline p = Pipeline.create(pipelineOptions);
        PCollectionTuple results = p
                .apply(Create.<GcsPath>of(getHarBucket(options)).withCoder(GcsPathCoder.of()))
                .apply(ParDo.named("expand-glob").of(new ExpandGlobFn()))
                .apply(Flatten.<GcsPath>iterables())
                .apply(WithKeys.of(
                        new SerializableFunction<GcsPath, Integer>() {
                    @Override
                    public Integer apply(GcsPath path) {
                        return path.hashCode();
                    }
                }))
                .apply(Reshuffle.<Integer, GcsPath>of())
                .apply(Values.<GcsPath>create())
                .apply(ParDo
                        .named("split-har")
                        .withOutputTags(
                                BigQueryImport.PAGES_TAG,
                                TupleTagList.of(BigQueryImport.ENTRIES_TAG)
                                .and(BigQueryImport.BODIES_TAG)
                                .and(BigQueryImport.LIGHTHOUSE_TAG)
                                .and(BigQueryImport.APPS_TAG))
                        .of(new DataExtractorFn())
                );

        List<TableFieldSchema> page = new ArrayList<>();
        page.add(new TableFieldSchema().setName("url").setType("STRING")
                .setDescription("URL of the parent document"));
        page.add(new TableFieldSchema().setName("payload").setType("STRING")
                .setDescription("JSON-encoded parent document HAR data"));
        TableSchema pageSchema = new TableSchema().setFields(page);

        PCollection<TableRow> pages = results.get(BigQueryImport.PAGES_TAG);
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

        PCollection<TableRow> entries = results.get(BigQueryImport.ENTRIES_TAG);
        entries.apply(BigQueryIO.Write
                .named("write-entries")
                .to(getBigQueryOutput(options, "requests"))
                .withSchema(reqSchema)
                .withCreateDisposition(BigQueryIO.Write.CreateDisposition.CREATE_IF_NEEDED)
                .withWriteDisposition(BigQueryIO.Write.WriteDisposition.WRITE_TRUNCATE));

        List<TableFieldSchema> body = new ArrayList<>();
        body.add(new TableFieldSchema().setName("page").setType("STRING")
                .setDescription("URL of the parent document"));
        body.add(new TableFieldSchema().setName("url").setType("STRING")
                .setDescription("URL of the subresource"));
        body.add(new TableFieldSchema().setName("body").setType("STRING")
                .setDescription("Body of the response"));
        body.add(new TableFieldSchema().setName("truncated").setType("BOOLEAN")
                .setDescription("Flag is true if body is >2MB"));
        TableSchema bodySchema = new TableSchema().setFields(body);

        PCollection<TableRow> bodies = results.get(BigQueryImport.BODIES_TAG);
        bodies.apply(BigQueryIO.Write
                .named("write-bodies")
                .to(getBigQueryOutput(options, "response_bodies"))
                .withSchema(bodySchema)
                .withCreateDisposition(BigQueryIO.Write.CreateDisposition.CREATE_IF_NEEDED)
                .withWriteDisposition(BigQueryIO.Write.WriteDisposition.WRITE_TRUNCATE));

        List<TableFieldSchema> lhReport = new ArrayList<>();
        lhReport.add(new TableFieldSchema().setName("url").setType("STRING")
                .setDescription("URL of the parent document"));
        lhReport.add(new TableFieldSchema().setName("report").setType("STRING")
                .setDescription("JSON-encoded Lighthouse report"));
        TableSchema lhReportSchema = new TableSchema().setFields(lhReport);

        PCollection<TableRow> lhReports = results.get(BigQueryImport.LIGHTHOUSE_TAG);
        lhReports.apply(BigQueryIO.Write
                .named("write-lighthouse")
                .to(getBigQueryOutput(options, "lighthouse"))
                .withSchema(lhReportSchema)
                .withCreateDisposition(BigQueryIO.Write.CreateDisposition.CREATE_IF_NEEDED)
                .withWriteDisposition(BigQueryIO.Write.WriteDisposition.WRITE_TRUNCATE));

        List<TableFieldSchema> app = new ArrayList<>();
        app.add(new TableFieldSchema().setName("url").setType("STRING")
                .setDescription("URL of the parent document"));
        app.add(new TableFieldSchema().setName("category").setType("STRING")
                .setDescription("The type of app"));
        app.add(new TableFieldSchema().setName("app").setType("STRING")
                .setDescription("Name of the detected app"));
        app.add(new TableFieldSchema().setName("info").setType("STRING")
                .setDescription("Additional information known about the app"));
        TableSchema appSchema = new TableSchema().setFields(app);

        PCollection<TableRow> apps = results.get(BigQueryImport.APPS_TAG);
        apps.apply(BigQueryIO.Write
                .named("write-apps")
                .to(getBigQueryOutput(options, "technologies"))
                .withSchema(appSchema)
                .withCreateDisposition(BigQueryIO.Write.CreateDisposition.CREATE_IF_NEEDED)
                .withWriteDisposition(BigQueryIO.Write.WriteDisposition.WRITE_TRUNCATE));

        p.run();
    }
}
