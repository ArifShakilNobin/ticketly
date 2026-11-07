package com.ticketly.booking.service;

import org.junit.jupiter.api.Test;

import java.util.HashSet;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PnrGeneratorTest {

    @Test
    void pnrMatchesTheExpectedFormat() {
        String pnr = PnrGenerator.generate();

        assertTrue(pnr.matches("^TK[A-Z0-9]{6}$"),
                "PNR must be 'TK' + 6 uppercase alphanumerics but was: " + pnr);
        assertEquals("TK", PnrGenerator.prefix());
    }

    @Test
    void generatedPnrsAreUniqueOverAThousandDraws() {
        Set<String> seen = new HashSet<>();
        int draws = 10_000;
        for (int i = 0; i < draws; i++) {
            seen.add(PnrGenerator.generate());
        }
        // 36^6 ≈ 2.18 billion combinations → zero collisions in 10k draws is expected
        assertEquals(draws, seen.size(), "PNR generator produced a duplicate");
    }
}
