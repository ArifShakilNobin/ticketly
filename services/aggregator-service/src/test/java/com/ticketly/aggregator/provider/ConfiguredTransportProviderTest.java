package com.ticketly.aggregator.provider;

import com.ticketly.aggregator.config.ProviderProperties;
import com.ticketly.common.dto.TransportType;
import com.ticketly.common.dto.search.FareItem;
import com.ticketly.common.dto.search.SearchRequest;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ConfiguredTransportProviderTest {

    private static final SearchRequest REQUEST = new SearchRequest(
            "ঢাকা", "খুলনা", LocalDate.of(2026, 11, 13), TransportType.ALL, null, null, null);

    private final FareMockGenerator generator = new FareMockGenerator();

    @Test
    void disabledClientGoesStraightToTheMock() {
        ConfiguredTransportProvider provider = build(new DisabledProviderClient());

        assertFalse(provider.isLive());
        assertFalse(provider.search(REQUEST).isEmpty());
        assertEquals(TransportType.BUS, provider.type());
        assertEquals("Bus Network", provider.name());
    }

    @Test
    void failingPartnerFallsBackToTheMockInsteadOfThrowing() {
        ProviderClient broken = new ProviderClient() {
            @Override
            public boolean isEnabled() {
                return true;
            }

            @Override
            public List<FareItem> fetch(SearchRequest request) {
                throw new IllegalStateException("partner is down");
            }
        };

        ConfiguredTransportProvider provider = build(broken);
        List<FareItem> fares = provider.search(REQUEST);

        assertTrue(provider.isLive());
        assertFalse(fares.isEmpty(), "a broken partner must not empty the results");
    }

    @Test
    void emptyPartnerResponseFallsBackToTheMock() {
        ProviderClient empty = new ProviderClient() {
            @Override
            public boolean isEnabled() {
                return true;
            }

            @Override
            public List<FareItem> fetch(SearchRequest request) {
                return List.of();
            }
        };

        assertFalse(build(empty).search(REQUEST).isEmpty());
    }

    @Test
    void livePartnerResponseIsUsedWhenItHasData() {
        FareItem live = new FareItem("live-1", "Partner", "P-1", TransportType.BUS, "ঢাকা", "খুলনা",
                LocalDate.of(2026, 11, 13), java.time.LocalTime.of(8, 0), java.time.LocalTime.of(14, 0),
                360, java.math.BigDecimal.valueOf(700), "BDT", 30, "AC",
                "Flexible", java.util.Map.of());
        ProviderClient healthy = new ProviderClient() {
            @Override
            public boolean isEnabled() {
                return true;
            }

            @Override
            public List<FareItem> fetch(SearchRequest request) {
                return List.of(live);
            }
        };

        List<FareItem> fares = build(healthy).search(REQUEST);
        assertEquals(1, fares.size());
        assertEquals("live-1", fares.get(0).id());
    }

    @Test
    void registryRespectsTheRequestedMode() {
        ProviderProperties.Mode mode = new ProviderProperties.Mode();
        mode.setName("Bus Network");
        mode.setPartners(List.of("Shohoz"));
        ConfiguredTransportProvider bus = new ConfiguredTransportProvider(
                TransportType.BUS, mode.getName(), mode.getPartners(),
                new DisabledProviderClient(), generator);

        ProviderRegistry registry = new ProviderRegistry(java.util.Map.of(TransportType.BUS, bus));
        assertEquals(1, registry.resolve(TransportType.BUS).size());
        assertTrue(registry.resolve(TransportType.TRAIN).isEmpty());
        assertEquals(1, registry.resolve(TransportType.ALL).size());
        assertEquals(1, registry.resolve(null).size());
    }

    private ConfiguredTransportProvider build(ProviderClient client) {
        ProviderProperties.Mode mode = new ProviderProperties.Mode();
        mode.setName("Bus Network");
        mode.setPartners(List.of("Shohoz", "Green Line"));
        return ConfiguredTransportProvider.from(mode, TransportType.BUS, client, generator);
    }
}
