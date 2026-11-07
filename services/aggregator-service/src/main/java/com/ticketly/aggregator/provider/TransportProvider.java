package com.ticketly.aggregator.provider;

import com.ticketly.common.dto.TransportType;
import com.ticketly.common.dto.search.FareItem;
import com.ticketly.common.dto.search.SearchRequest;

import java.util.List;

/** One transport mode's provider network (train / bus / launch / flight). */
public interface TransportProvider {

    TransportType type();

    /** Stable logical name used in logs and fare ids. */
    String name();

    /**
     * Runs the provider (HTTP client when configured, deterministic mock
     * otherwise). Implementations must never let a partner failure escape.
     */
    List<FareItem> search(SearchRequest request);
}
