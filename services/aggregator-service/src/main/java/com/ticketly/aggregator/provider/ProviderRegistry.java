package com.ticketly.aggregator.provider;

import com.ticketly.common.dto.TransportType;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;

/** Read-only view over the configured transport providers. */
public class ProviderRegistry {

    private final Map<TransportType, TransportProvider> providers;

    public ProviderRegistry(Map<TransportType, TransportProvider> providers) {
        Map<TransportType, TransportProvider> copy = new EnumMap<>(TransportType.class);
        if (providers != null) {
            copy.putAll(providers);
        }
        this.providers = Map.copyOf(copy);
    }

    /** Providers that should answer the request ({@code ALL} → every mode). */
    public List<TransportProvider> resolve(TransportType requested) {
        if (requested == null || requested == TransportType.ALL) {
            return all();
        }
        TransportProvider provider = providers.get(requested);
        return provider == null ? List.of() : List.of(provider);
    }

    public List<TransportProvider> all() {
        return new ArrayList<>(providers.values());
    }

    public int size() {
        return providers.size();
    }
}
