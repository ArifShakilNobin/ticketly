package com.ticketly.aggregator.provider;

import com.ticketly.aggregator.config.ProviderProperties;
import com.ticketly.common.dto.TransportType;
import com.ticketly.common.dto.search.FareItem;
import com.ticketly.common.dto.search.SearchRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

/**
 * A {@link TransportProvider} backed by a {@link ProviderClient}.
 *
 * <p>Resolution order: live HTTP client when a partner {@code base-url} is configured
 * → deterministic mock when the client is disabled, returns nothing or throws.
 * A partner failure is never allowed to escape.</p>
 */
public class ConfiguredTransportProvider implements TransportProvider {

    private static final Logger log = LoggerFactory.getLogger(ConfiguredTransportProvider.class);

    private final TransportType type;
    private final String name;
    private final List<String> partners;
    private final ProviderClient client;
    private final FareMockGenerator mockGenerator;

    public ConfiguredTransportProvider(TransportType type, String name, List<String> partners,
                                       ProviderClient client, FareMockGenerator mockGenerator) {
        this.type = type;
        this.name = name;
        this.partners = partners == null ? List.of() : List.copyOf(partners);
        this.client = client;
        this.mockGenerator = mockGenerator;
    }

    public static ConfiguredTransportProvider from(ProviderProperties.Mode mode,
                                                   TransportType type,
                                                   ProviderClient client,
                                                   FareMockGenerator mockGenerator) {
        return new ConfiguredTransportProvider(
                type,
                mode.getName(),
                mode.getPartners(),
                client,
                mockGenerator);
    }

    @Override
    public TransportType type() {
        return type;
    }

    @Override
    public String name() {
        return name;
    }

    @Override
    public List<FareItem> search(SearchRequest request) {
        if (client != null && client.isEnabled()) {
            try {
                List<FareItem> live = client.fetch(request);
                if (live != null && !live.isEmpty()) {
                    return live;
                }
                log.warn("{} returned no fares, falling back to the offline generator", name);
            } catch (Exception ex) {
                log.warn("{} partner call failed ({}), falling back to the offline generator",
                        name, ex.toString());
            }
        }
        List<FareItem> mock = mockGenerator.generate(name, type, partners, request);
        if (mock.isEmpty()) {
            log.debug("{} produced no fares for {} -> {}", name, request.source(), request.destination());
        }
        return mock;
    }

    /** True when this provider would call a real partner endpoint. */
    public boolean isLive() {
        return client != null && client.isEnabled();
    }
}
