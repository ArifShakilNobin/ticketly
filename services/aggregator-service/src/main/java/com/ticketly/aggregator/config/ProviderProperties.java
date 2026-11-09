package com.ticketly.aggregator.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.List;

/**
 * Configuration of the four provider networks:
 *
 * <pre>
 * providers:
 *   train:
 *     enabled: true
 *     base-url:                                 # blank = deterministic offline generator
 *     name: Rail Sheba                          # display name used in fares and logs
 *     partners: [Rail Sheba, Bangladesh Railway]
 *   bus: { ... }
 *   launch: { ... }
 *   flight: { ... }
 * </pre>
 *
 * <p>Every field has a sensible default, so an empty {@code providers:} block still
 * yields a fully working (offline) platform.</p>
 */
@ConfigurationProperties(prefix = "providers")
public class ProviderProperties {

    private Mode train = new Mode();
    private Mode bus = new Mode();
    private Mode launch = new Mode();
    private Mode flight = new Mode();

    public Mode getTrain() {
        return train;
    }

    public void setTrain(Mode train) {
        this.train = train;
    }

    public Mode getBus() {
        return bus;
    }

    public void setBus(Mode bus) {
        this.bus = bus;
    }

    public Mode getLaunch() {
        return launch;
    }

    public void setLaunch(Mode launch) {
        this.launch = launch;
    }

    public Mode getFlight() {
        return flight;
    }

    public void setFlight(Mode flight) {
        this.flight = flight;
    }

    /** Lookup by the lowercase yml key ({@code train} | {@code bus} | {@code launch} | {@code flight}). */
    public Mode mode(String key) {
        if (key == null) {
            return null;
        }
        return switch (key) {
            case "train" -> train;
            case "bus" -> bus;
            case "launch" -> launch;
            case "flight" -> flight;
            default -> null;
        };
    }

    public static class Mode {

        /** When false the mode is served entirely by the offline generator. */
        private boolean enabled = true;

        /** Partner endpoint; blank means "no live integration configured". */
        private String baseUrl = "";

        /** Display name used in fares, badges and logs. */
        private String name;

        /** Operator brands whose seats are aggregated for this mode. */
        private List<String> partners = List.of();

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }

        public String getBaseUrl() {
            return baseUrl;
        }

        public void setBaseUrl(String baseUrl) {
            this.baseUrl = baseUrl;
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public List<String> getPartners() {
            return partners;
        }

        public void setPartners(List<String> partners) {
            this.partners = partners == null ? List.of() : partners;
        }
    }
}
