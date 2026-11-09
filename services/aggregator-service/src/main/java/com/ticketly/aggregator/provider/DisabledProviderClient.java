package com.ticketly.aggregator.provider;

import com.ticketly.common.dto.search.FareItem;
import com.ticketly.common.dto.search.SearchRequest;

import java.util.List;

/** Client used when a provider mode is switched off — it always goes to the mock. */
public class DisabledProviderClient implements ProviderClient {

    @Override
    public boolean isEnabled() {
        return false;
    }

    @Override
    public List<FareItem> fetch(SearchRequest request) {
        return List.of();
    }
}
