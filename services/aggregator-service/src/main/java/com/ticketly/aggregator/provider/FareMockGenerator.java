package com.ticketly.aggregator.provider;

import com.ticketly.common.dto.TransportType;
import com.ticketly.common.dto.search.FareItem;
import com.ticketly.common.dto.search.SearchRequest;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Random;

/**
 * Deterministic fare generator used whenever a partner base-url is blank or the
 * partner call fails. The {@link Random} is seeded from (provider + route +
 * travel date + mode), so the same query always yields the same fares, while
 * ranges stay realistic per transport mode:
 *
 * <ul>
 *   <li>train – 4–9 h, ৳350–1200</li>
 *   <li>bus – 4–8 h, ৳450–1100</li>
 *   <li>launch – 6–14 h, ৳300–800</li>
 *   <li>flight – 55–90 min, ৳3500–8500</li>
 * </ul>
 */
@Component
public class FareMockGenerator {

    /** Per-mode duration / fare envelope plus class and policy text. */
    record ModeProfile(int minDurationMins, int maxDurationMins, int minFare, int maxFare,
                       String[] classes, String cancellationPolicy) {
    }

    static final Map<TransportType, ModeProfile> PROFILES = Map.of(
            TransportType.TRAIN, new ModeProfile(240, 540, 350, 1200,
                    new String[]{"AC Berth", "AC Seat", "Non-AC", "Sleeper"},
                    "Free cancellation up to 4 hours before departure; 50% refund within 2 hours."),
            TransportType.BUS, new ModeProfile(240, 480, 450, 1100,
                    new String[]{"AC", "Non-AC", "Sleeper"},
                    "Free cancellation up to 1 hour before departure; no refund afterwards."),
            TransportType.LAUNCH, new ModeProfile(360, 840, 300, 800,
                    new String[]{"Economy", "Business", "Deck"},
                    "Free cancellation up to 6 hours before departure; 50% refund within 3 hours."),
            TransportType.FLIGHT, new ModeProfile(55, 90, 3500, 8500,
                    new String[]{"Economy", "Business"},
                    "Refundable up to 24 hours before departure; date change allowed for a fee."));

    private static final String[] COACH_TYPES = {"AC Non-AC", "AC Sleeper", "Double-Decker", "Non-AC"};
    private static final String[] VESSELS = {"MV Silkcity", "MV Sourabhi", "MV Nabiha",
            "MV Parabat", "MV Sundarbans", "MV Atria"};
    private static final String[] QUOTAS = {"General", "Sheba", "Ladies"};

    /** Generates 3–6 stable fares for the request. */
    public List<FareItem> generate(String providerName, TransportType type,
                                   List<String> partners, SearchRequest request) {
        ModeProfile profile = PROFILES.get(type);
        if (profile == null || partners == null || partners.isEmpty()) {
            return List.of();
        }
        LocalDate date = request.safeTravelDate();
        Random random = new Random(seed(providerName, request, date, type));
        int count = 3 + random.nextInt(4); // 3..6

        List<FareItem> fares = new ArrayList<>(count);
        String idToken = Integer.toUnsignedString((int) seed(providerName, request, date, type), 36);
        for (int i = 0; i < count; i++) {
            String partner = partners.get(random.nextInt(partners.size()));
            String vehicleClass = profile.classes()[random.nextInt(profile.classes().length)];
            LocalTime depart = LocalTime.of(6, 0)
                    .plusMinutes(random.nextInt(17 * 60 + 1)); // 06:00 – 23:00
            int duration = profile.minDurationMins()
                    + random.nextInt(profile.maxDurationMins() - profile.minDurationMins() + 1);
            int fare = roundTo5(profile.minFare()
                    + random.nextInt(profile.maxFare() - profile.minFare() + 1));
            int seats = 5 + random.nextInt(56); // 5 – 60
            String providerSlug = type.name().toLowerCase();

            fares.add(new FareItem(
                    providerSlug + "-" + idToken + "-" + i,
                    partner,
                    providerRef(partner, date, i),
                    type,
                    request.source(),
                    request.destination(),
                    date,
                    depart,
                    depart.plusMinutes(duration),
                    duration,
                    BigDecimal.valueOf(fare),
                    "BDT",
                    seats,
                    vehicleClass,
                    profile.cancellationPolicy(),
                    meta(type, partner, vehicleClass, random)));
        }
        return List.copyOf(fares);
    }

    private static long seed(String providerName, SearchRequest request, LocalDate date,
                             TransportType type) {
        int hash = Objects.hashCode(providerName);
        hash = 31 * hash + String.valueOf(request.source()).hashCode();
        hash = 31 * hash + String.valueOf(request.destination()).hashCode();
        hash = 31 * hash + date.toString().hashCode();
        hash = 31 * hash + type.name().hashCode();
        return hash;
    }

    private static int roundTo5(int value) {
        int rounded = (int) Math.round(value / 5.0) * 5;
        return Math.max(0, rounded);
    }

    /** Partner initials, e.g. "Rail Sheba" → "RS", "US-Bangla" → "UB". */
    static String providerRef(LocalDate date, int index, String initials) {
        return initials + "-" + date.toString().replace("-", "") + "-" + String.format("%02d", index);
    }

    private static String providerRef(String partner, LocalDate date, int index) {
        return providerRef(date, index, initials(partner));
    }

    static String initials(String partner) {
        StringBuilder out = new StringBuilder();
        for (String token : partner.split("[^A-Za-z0-9]+")) {
            if (!token.isEmpty()) {
                out.append(Character.toUpperCase(token.charAt(0)));
            }
        }
        return out.length() == 0 ? "XX" : out.toString();
    }

    private static Map<String, String> meta(TransportType type, String partner,
                                            String vehicleClass, Random random) {
        Map<String, String> meta = new LinkedHashMap<>();
        switch (type) {
            case BUS -> {
                meta.put("operator", partner);
                meta.put("coachType", COACH_TYPES[random.nextInt(COACH_TYPES.length)]);
                meta.put("luggage", "15 kg");
            }
            case TRAIN -> {
                meta.put("operator", partner);
                meta.put("trainNo", String.valueOf(700 + random.nextInt(99)));
                meta.put("quota", QUOTAS[random.nextInt(QUOTAS.length)]);
                meta.put("coachType", vehicleClass);
            }
            case LAUNCH -> {
                meta.put("operator", partner);
                meta.put("vessel", VESSELS[random.nextInt(VESSELS.length)]);
                meta.put("cabinType", vehicleClass);
            }
            case FLIGHT -> {
                meta.put("operator", partner);
                meta.put("flightNo", initials(partner) + "-" + (100 + random.nextInt(900)));
                meta.put("baggage", "20 kg checked + 7 kg cabin");
                meta.put("meal", "Snack included");
            }
            default -> meta.put("operator", partner);
        }
        return meta;
    }
}
