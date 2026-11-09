package com.ticketly.aggregator.service;

import com.ticketly.common.dto.TransportType;
import com.ticketly.common.dto.search.SearchRequest;
import com.ticketly.common.web.ApiException;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

class SearchServiceTest {

    @Test
    void trimsAndTitleCasesLatinRoutes() {
        SearchRequest normalised = SearchService.normalise(
                new SearchRequest("  dhaka   theke  ", "KHULNA", LocalDate.of(2026, 11, 13),
                        null, null, null, "s1"));

        assertEquals("Dhaka Theke", normalised.source());
        assertEquals("Khulna", normalised.destination());
        assertEquals(TransportType.ALL, normalised.safeTransportType());
        assertEquals(LocalDate.of(2026, 11, 13), normalised.travelDate());
        assertEquals("s1", normalised.sessionId());
    }

    @Test
    void leavesBengaliRoutesUntouched() {
        SearchRequest normalised = SearchService.normalise(
                new SearchRequest(" ঢাকা ", "খুলনা", null, TransportType.TRAIN, null, null, null));

        assertEquals("ঢাকা", normalised.source());
        assertEquals("খুলনা", normalised.destination());
        assertEquals(TransportType.TRAIN, normalised.transportType());
        assertNotNull(normalised.travelDate(), "date defaults to today");
    }

    @Test
    void rejectsMissingRoute() {
        ApiException source = assertThrows(ApiException.class,
                () -> SearchService.normalise(new SearchRequest(" ", "খুলনা", null, null, null, null, null)));
        assertEquals(400, source.getStatus());

        ApiException destination = assertThrows(ApiException.class,
                () -> SearchService.normalise(new SearchRequest("ঢাকা", null, null, null, null, null, null)));
        assertEquals(400, destination.getStatus());
    }

    @Test
    void rejectsIdenticalSourceAndDestination() {
        ApiException ex = assertThrows(ApiException.class,
                () -> SearchService.normalise(new SearchRequest("Dhaka", "  dhaka ", null, null, null, null, null)));
        assertEquals(400, ex.getStatus());
    }

    @Test
    void rejectsAnEmptyBody() {
        assertThrows(ApiException.class, () -> SearchService.normalise(null));
    }

    @Test
    void keepsBudgetAndPriorityInNormalisedRequest() {
        SearchRequest normalised = SearchService.normalise(
                new SearchRequest("ঢাকা", "খুলনা", LocalDate.now(), TransportType.BUS,
                        new BigDecimal("500"), null, null));

        assertEquals(new BigDecimal("500"), normalised.budgetLimit());
        assertNotNull(normalised.safePriority());
    }
}
