package com.ticketly.aggregator.config;

import com.ticketly.aggregator.provider.ConfiguredTransportProvider;
import com.ticketly.aggregator.provider.DisabledProviderClient;
import com.ticketly.aggregator.provider.FareMockGenerator;
import com.ticketly.aggregator.provider.HttpProviderClient;
import com.ticketly.aggregator.provider.ProviderClient;
import com.ticketly.aggregator.provider.ProviderRegistry;
import com.ticketly.aggregator.provider.TransportProvider;
import com.ticketly.common.dto.TransportType;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Builds one {@link TransportProvider} per transport mode from {@code providers.*}
 * configuration and exposes them through a {@link ProviderRegistry}.
 */
@Configuration
@EnableConfigurationProperties(ProviderProperties.class)
public class ProviderConfiguration {

    /** Fallback display names when the yml does not spell them out. */
    private static final Map<TransportType, String> DEFAULT_NAMES = Map.of(
            TransportType.TRAIN, "Rail Sheba",
            TransportType.BUS, "Bus Network",
            TransportType.LAUNCH, "Launch Network",
            TransportType.FLIGHT, "Domestic Airlines");

    /** Fallback partner lists when the yml does not spell them out. */
    private static final Map<TransportType, List<String>> DEFAULT_PARTNERS = Map.of(
            TransportType.TRAIN, List.of("Rail Sheba", "Bangladesh Railway"),
            TransportType.BUS, List.of("Shohoz", "bdtickets", "Green Line", "Hanif", "Ena"),
            TransportType.LAUNCH, List.of("Bangladesh Inland Water Transport", "Padma Line",
                    "Turag Paribahan", "Karnaphuli Line"),
            TransportType.FLIGHT, List.of("US-Bangla", "Novoair", "Air Astra"));

    @Bean
    public ProviderRegistry providerRegistry(ProviderProperties properties,
                                             FareMockGenerator mockGenerator) {
        Map<TransportType, TransportProvider> providers = new EnumMap<>(TransportType.class);

        for (Map.Entry<TransportType, ProviderProperties.Mode> entry : modes(properties).entrySet()) {
            TransportType type = entry.getKey();
            ProviderProperties.Mode mode = entry.getValue() == null
                    ? new ProviderProperties.Mode()
                    : entry.getValue();

            String name = blankTo(mode.getName(), DEFAULT_NAMES.get(type));
            List<String> partners = mode.getPartners().isEmpty()
                    ? DEFAULT_PARTNERS.get(type)
                    : mode.getPartners();

            ProviderClient client = mode.isEnabled()
                    ? new HttpProviderClient(type, mode.getBaseUrl())
                    : new DisabledProviderClient();

            providers.put(type, new ConfiguredTransportProvider(type, name, partners, client, mockGenerator));
        }
        return new ProviderRegistry(providers);
    }

    private static Map<TransportType, ProviderProperties.Mode> modes(ProviderProperties properties) {
        Map<TransportType, ProviderProperties.Mode> modes = new LinkedHashMap<>();
        modes.put(TransportType.TRAIN, properties.getTrain());
        modes.put(TransportType.BUS, properties.getBus());
        modes.put(TransportType.LAUNCH, properties.getLaunch());
        modes.put(TransportType.FLIGHT, properties.getFlight());
        return modes;
    }

    private static String blankTo(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }
}
