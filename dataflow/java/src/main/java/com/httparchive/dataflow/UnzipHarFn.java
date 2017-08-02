package com.httparchive.dataflow;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.node.ObjectNode;

import com.google.cloud.dataflow.sdk.util.GcsUtil;
import com.google.cloud.dataflow.sdk.util.GcsUtil.GcsUtilFactory;
import com.google.cloud.dataflow.sdk.util.gcsfs.GcsPath;
import com.google.cloud.dataflow.sdk.transforms.DoFn;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.channels.Channels;
import java.nio.channels.SeekableByteChannel;
import java.util.zip.GZIPInputStream;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class UnzipHarFn extends DoFn<GcsPath, JsonNode> {

    private static final Logger LOG
            = LoggerFactory.getLogger(UnzipHarFn.class);

    private static final ObjectMapper MAPPER
            = new ObjectMapper().disable(SerializationFeature.FAIL_ON_EMPTY_BEANS);

    private byte[] unzipGcsFile(GcsPath zipFile, GcsUtil gcsUtil) throws IOException {
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

    private JsonNode decodeHar(GcsPath harFile, GcsUtil gcsUtil) throws IOException {
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
            c.output(har);
        } catch (IOException e) {
            LOG.error("Failed to unzip HAR: {}", e);
        }
    }

}
