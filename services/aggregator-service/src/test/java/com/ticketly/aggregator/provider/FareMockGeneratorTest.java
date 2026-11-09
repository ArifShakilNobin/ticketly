package com.ticketly.aggregator.provider;

import com.ticketly.common.dto.TransportType;
import com.ticketly.common.dto.search.FareItem;
import com.ticketly.common.dto.search.SearchRequest;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class FareMockGeneratorTest {

    private static final LocalDate DATE = LocalDate.of(2026, 11, 13);

    private final FareMockGenerator generator = new FareMockGenerator();

    private static SearchRequest request() {
        return new SearchRequest("ঢাকা", "খুলনা", DATE, TransportType.ALL, null, null, "test-session");
    }

    @Test
    void producesStableResultsForTheSameQuery() {
        List<FareItem> first = generator.generate("Shohoz", TransportType.BUS,
                List.of("Shohoz", "Green Line"), request());
        List<FareItem> second = generator.generate("Shohoz", TransportType.BUS,
                List.of("Shohoz", "Green Line"), request());

        assertEquals(first.size(), second.size());
        assertFalse(first.isEmpty());
        for (int i = 0; i < first.size(); i++) {
            assertEquals(first.get(i).id(), second.get(i).id());
            assertEquals(first.get(i).baseFare(), second.get(i).baseFare());
            assertEquals(first.get(i).departTime(), second.get(i).departTime());
        }
    }

    @Test
    void differentRoutesProduceDifferentFares() {
        SearchRequest other = new SearchRequest("ঢাকা", "চট্টগ্রাম", DATE, TransportType.ALL, null, null, null);
        List<FareItem> a = generator.generate("Shohoz", TransportType.BUS, List.of("Shohoz"), request());
        List<FareItem> b = generator.generate("Shohoz", TransportType.BUS, List.of("Shohoz"), other);

        assertFalse(a.get(0).id().equals(b.get(0).id())
                && a.get(0).baseFare().equals(b.get(0).baseFare()));
    }

    @Test
    void faresStayInsideTheDocumentedEnvelope() {
        for (TransportType type : List.of(TransportType.TRAIN, TransportType.BUS,
                TransportType.LAUNCH, TransportType.FLIGHT)) {
            FareMockGenerator.ModeProfile profile = FareMockGenerator.PROFILES.get(type);
            List<FareItem> fares = generator.generate("Test", type, List.of("A"), request());

            assertTrue(fares.size() >= 3 && fares.size() <= 6,
                    type + " should produce 3-6 fares, got " + fares.size());
            for (FareItem fare : fares) {
                assertEquals(type, fare.transportType());
                assertEquals("BDT", fare.currency());
                assertTrue(fare.durationMins() >= profile.minDurationMins()
                                && fare.durationMins() <= profile.maxDurationMins(),
                        type + " duration out of range: " + fare.durationMins());
                BigDecimal amount = fare.baseFare();
                assertTrue(amount.intValue() >= profile.minFare() && amount.intValue() <= profile.maxFare(),
                        type + " fare out of range: " + amount);
                assertTrue(fare.seatsAvailable() >= 1 && fare.seatsAvailable() <= 60);
                assertNotNull(fare.meta());
                assertFalse(fare.meta().isEmpty());
                assertEquals(fare.travelDate(), DATE);
                assertTrue(fare.departTime().isBefore(fare.arriveTime())
                                || fare.arriveTime().isBefore(fare.departTime()),
                        "arrival must exist");
            }
        }
    }

    @Test
    void fareIdsAreUniqueWithinAQuery() {
        List<FareItem> fares = generator.generate("Test", TransportType.FLIGHT,
                List.of("US-Bangla", "Novoair"), request());
        Set<String> ids = new HashSet<>();
        for (FareItem fare : fares) {
            assertTrue(ids.add(fare.id()), "duplicate id " + fare.id());
        }
    }

    @Test
    void unknownModeOrNoPartnersYieldsNothing() {
        assertTrue(generator.generate("Test", TransportType.ALL, List.of("A"), request()).isEmpty());
        assertTrue(generator.generate("Test", TransportType.BUS, List.of(), request()).isEmpty());
    }

    @Test
    void initialsAreDerivedFromPartnerNames() {
        assertEquals("RS", FareMockGenerator.initials("Rail Sheba"));
        assertEquals("UB", FareMockGenerator.initials("US-Bangla"));
        assertEquals("XX", FareMockGenerator.initials("???"));
    }
}
