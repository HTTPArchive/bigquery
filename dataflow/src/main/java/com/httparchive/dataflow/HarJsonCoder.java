/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.httparchive.dataflow;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.google.cloud.dataflow.sdk.coders.AtomicCoder;
import com.google.cloud.dataflow.sdk.coders.Coder.Context;
import com.google.cloud.dataflow.sdk.coders.StringUtf8Coder;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.ByteBuffer;

/**
 *
 * @author igrigorik
 */
public class HarJsonCoder extends AtomicCoder<JsonNode> {

    public static HarJsonCoder of() {
        return INSTANCE;
    }

    @Override
    public void encode(JsonNode value, OutputStream outStream, Context context)
            throws IOException {
        String strValue = MAPPER.writeValueAsString(value);
        StringUtf8Coder.of().encode(strValue, outStream, context);
    }

    public JsonNode decode(ByteBuffer in) throws IOException {
        try {
            return MAPPER.readTree(in.toString());
        } catch (IOException e) {
            System.out.println("Failed to decode HAR: " + e);
            System.out.println(in);
            throw e;
        }
    }

    @Override
    public JsonNode decode(InputStream inStream, Context context) throws IOException {
        try {
            String strValue = StringUtf8Coder.of().decode(inStream, context);
            return MAPPER.readTree(strValue);
        } catch (IOException e) {
            System.out.println("Failed to decode HAR: " + e);
            System.out.println(inStream);
            System.out.println(context);
            throw e;
        }
    }

    private static final ObjectMapper MAPPER
            = new ObjectMapper().disable(SerializationFeature.FAIL_ON_EMPTY_BEANS);

    private static final HarJsonCoder INSTANCE = new HarJsonCoder();

    /**
     * TableCell can hold arbitrary Object instances, which makes the encoding
     * non-deterministic.
     */
    @Override
    @Deprecated
    public boolean isDeterministic() {
        return false;
    }

    @Override
    public void verifyDeterministic() throws NonDeterministicException {
        throw new NonDeterministicException(this,
                "HAR can hold arbitrary instances which may be non-deterministic.");
    }
}
