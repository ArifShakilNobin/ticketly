package com.ticketly.aggregator.provider;

import com.ticketly.common.dto.search.FareItem;
import com.ticketly.common.dto.search.SearchRequest;

import java.util.List;

/**
 * HTTP leg of a {@link TransportProvider}. {@link #isEnabled()} reports whether a
 * real partner base-url is configured; when it is {@code false} — or when
 * {@link #fetch(SearchRequest)} throws — the provider falls back to its
 * deterministic mock generator.
 */
public interface ProviderClient {

    boolean isEnabled();

    List<FareItem> fetch(SearchRequest request);
}
