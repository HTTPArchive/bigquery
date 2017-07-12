/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.httparchive.dataflow;

import com.google.cloud.dataflow.sdk.coders.AtomicCoder;
import com.google.cloud.dataflow.sdk.coders.Coder.Context;
import com.google.cloud.dataflow.sdk.coders.StringUtf8Coder;
import com.google.cloud.dataflow.sdk.util.gcsfs.GcsPath;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.ByteBuffer;

public class GcsPathCoder extends AtomicCoder<GcsPath> {

    public static GcsPathCoder of() {
        return INSTANCE;
    }

    @Override
    public void encode(GcsPath value, OutputStream outStream, Context context)
            throws IOException {
        String strValue = value.toResourceName();
        StringUtf8Coder.of().encode(strValue, outStream, context);
    }

    public GcsPath decode(ByteBuffer in) {
        return GcsPath.fromResourceName(in.toString());
    }

    @Override
    public GcsPath decode(InputStream inStream, Context context) throws IOException {
        try {
            String strValue = StringUtf8Coder.of().decode(inStream, context);
            return GcsPath.fromResourceName(strValue);
        } catch (IOException e) {
            System.out.println("Failed to decode GcsPath: " + e);
            System.out.println(inStream);
            System.out.println(context);
            throw e;
        }
    }

    private static final GcsPathCoder INSTANCE = new GcsPathCoder();

    /**
     * TableCell can hold arbitrary Object instances, which makes the encoding
     * non-deterministic.
     *
     * @return
     */
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
