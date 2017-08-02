package com.httparchive.dataflow;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.google.cloud.dataflow.sdk.transforms.DoFn;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class AnnotateFn extends DoFn<JsonNode, JsonNode> {

    private static final Logger LOG
            = LoggerFactory.getLogger(AnnotateFn.class);

    private void annotatePage(ObjectNode page, JsonNode har) {
        ArrayNode annotations = page.putArray("annotations");

        // TODO: Append each annotation.
    }

    @Override
    public void processElement(ProcessContext c) {
        JsonNode har = c.element();
        JsonNode data = har.get("log");
        JsonNode pages = data.get("pages");

        if (pages.size() > 0) {
            annotatePage((ObjectNode) pages.get(0), har);
        }

        c.output(har);
    }

}
