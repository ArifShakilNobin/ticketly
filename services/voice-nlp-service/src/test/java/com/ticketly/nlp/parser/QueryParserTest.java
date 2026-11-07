package com.ticketly.nlp.parser;

import com.ticketly.common.dto.SearchPriority;
import com.ticketly.common.dto.TicketIntent;
import com.ticketly.common.dto.TransportType;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.DayOfWeek;
import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Plain JUnit tests for the rule-based parser — no Spring context, no I/O.
 * A fixed reference date (Monday 2026-11-02) keeps weekday resolution stable.
 */
class QueryParserTest {

    private static final LocalDate MONDAY = LocalDate.of(2026, 11, 2);

    private final QueryParser parser = new QueryParser();

    @Test
    void bengaliCheapestFridayRoute() {
        ParsedQuery q = parser.parse(
                "আগামী শুক্রবার ঢাকা থেকে খুলনার সবচেয়ে কম ভাড়ার টিকিট দেখাও", MONDAY);

        assertEquals(TicketIntent.SEARCH_TICKET, q.intent());
        assertEquals("ঢাকা", q.source());
        assertEquals("খুলনা", q.destination());
        assertEquals(TransportType.ALL, q.transportType());      // no transport word
        assertEquals(LocalDate.of(2026, 11, 6), q.travelDate()); // next Friday
        assertEquals(SearchPriority.CHEAPEST, q.priority());
        assertNull(q.budgetLimit());                             // "কম ভাড়া" is not a number
        assertTrue(q.confidence() >= 0.6 && q.confidence() <= 1.0);
        assertTrue(q.detectedTerms().contains("ঢাকা"));
        assertTrue(q.detectedTerms().contains("খুলনা"));
    }

    @Test
    void banglishRouteWithTrainBudgetAndTomorrow() {
        ParsedQuery q = parser.parse(
                "kal dhaka theke ctg train ticket 500 taka", MONDAY);

        assertEquals(TicketIntent.SEARCH_TICKET, q.intent());
        assertEquals("Dhaka", q.source());
        assertEquals("CTG", q.destination());
        assertEquals(TransportType.TRAIN, q.transportType());
        assertEquals(new BigDecimal("500"), q.budgetLimit());
        assertEquals(LocalDate.of(2026, 11, 3), q.travelDate()); // tomorrow
        assertTrue(q.confidence() >= 0.8);
    }

    @Test
    void bengaliBusRouteFromChattogramTomorrow() {
        ParsedQuery q = parser.parse("কাল চট্টগ্রাম থেকে ঢাকা বাস", MONDAY);

        assertEquals(TicketIntent.SEARCH_TICKET, q.intent());
        assertEquals("চট্টগ্রাম", q.source());
        assertEquals("ঢাকা", q.destination());
        assertEquals(TransportType.BUS, q.transportType());
        assertEquals(LocalDate.of(2026, 11, 3), q.travelDate());
        assertTrue(q.detectedTerms().contains("বাস"));
    }

    @Test
    void bengaliBookSentenceIsBookIntent() {
        ParsedQuery q = parser.parse("ঢাকা থেকে সিলেট ট্রেনের টিকিট কিনি", MONDAY);

        assertEquals(TicketIntent.BOOK_TICKET, q.intent());
        assertEquals("ঢাকা", q.source());
        assertEquals("সিলেট", q.destination());
        assertEquals(TransportType.TRAIN, q.transportType());
    }

    @Test
    void englishBookSentenceIsBookIntent() {
        ParsedQuery q = parser.parse("book me a dhaka to sylhet train ticket tomorrow", MONDAY);

        assertEquals(TicketIntent.BOOK_TICKET, q.intent());
        assertEquals("Dhaka", q.source());
        assertEquals("Sylhet", q.destination());
        assertEquals(TransportType.TRAIN, q.transportType());
        assertEquals(LocalDate.of(2026, 11, 3), q.travelDate());
    }

    @Test
    void bengaliDigitsInIsoDateAndBudget() {
        ParsedQuery q = parser.parse(
                "২০২৬-১১-১৬ তারিখে ঢাকা থেকে সিলেট ট্রেনের টিকিট ৫০০ টাকা", MONDAY);

        assertEquals(LocalDate.of(2026, 11, 16), q.travelDate());
        assertEquals(new BigDecimal("500"), q.budgetLimit());
        assertEquals("ঢাকা", q.source());
        assertEquals("সিলেট", q.destination());
        assertEquals(TransportType.TRAIN, q.transportType());
    }

    @Test
    void bengaliDayAndMonthDate() {
        ParsedQuery q = parser.parse("৮ নভেম্বর ঢাকা থেকে রাজশাহী", MONDAY);

        assertEquals(LocalDate.of(2026, 11, 8), q.travelDate());
        assertEquals("ঢাকা", q.source());
        assertEquals("রাজশাহী", q.destination());
        assertTrue(q.detectedTerms().stream().anyMatch(t -> t.contains("নভেম্বর")));
    }

    @Test
    void slashDateAndBudgetWord() {
        ParsedQuery q = parser.parse("budget 700 dhaka to ctg train 8/11/2026", MONDAY);

        assertEquals(LocalDate.of(2026, 11, 8), q.travelDate());
        assertEquals(new BigDecimal("700"), q.budgetLimit());
        assertEquals("Dhaka", q.source());
        assertEquals("CTG", q.destination());
    }

    @Test
    void pnrStatusIsCheckStatus() {
        ParsedQuery q = parser.parse("আমার pnr এর স্ট্যাটাস যাচাই করো", MONDAY);
        assertEquals(TicketIntent.CHECK_STATUS, q.intent());
    }

    @Test
    void bareDepartureQuestionIsCheckStatusButRoutePrefersSearch() {
        assertEquals(TicketIntent.CHECK_STATUS,
                parser.parse("ট্রেন কখন ছাড়বে", MONDAY).intent());
        assertEquals(TicketIntent.SEARCH_TICKET,
                parser.parse("ঢাকা থেকে খুলনার ট্রেন কখন ছাড়বে", MONDAY).intent());
    }

    @Test
    void singleCityBecomesDestinationUnlessAfterFrom() {
        ParsedQuery toCity = parser.parse("খুলনায় কাল যাবো", MONDAY);
        assertNull(toCity.source());
        assertEquals("খুলনা", toCity.destination());
        assertEquals(LocalDate.of(2026, 11, 3), toCity.travelDate());

        ParsedQuery fromCity = parser.parse("ঢাকা থেকে যাবো", MONDAY);
        assertEquals("ঢাকা", fromCity.source());
        assertNull(fromCity.destination());
    }

    @Test
    void noSignalsIsUnknownWithZeroConfidence() {
        ParsedQuery q = parser.parse("ধন্যবাদ", MONDAY);

        assertEquals(TicketIntent.UNKNOWN, q.intent());
        assertEquals(TransportType.ALL, q.transportType());
        assertNull(q.source());
        assertNull(q.destination());
        assertNull(q.travelDate());
        assertNull(q.budgetLimit());
        assertEquals(SearchPriority.BALANCED, q.priority());
        assertEquals(0.0, q.confidence());
        assertTrue(q.detectedTerms().isEmpty());
    }

    @Test
    void flightAndLaunchKeywordsAreRecognised() {
        assertEquals(TransportType.FLIGHT,
                parser.parse("কাল ঢাকা থেকে সিলেট ফ্লাইট", MONDAY).transportType());
        assertEquals(TransportType.LAUNCH,
                parser.parse("dhaka theke barisal launch ticket", MONDAY).transportType());
        assertEquals(TransportType.BUS,
                parser.parse("রংপুর থেকে ঢাকা বাস", MONDAY).transportType());
    }

    @Test
    void busIsNotDetectedInsideHouseNoun() {
        // বাসা (house) must not count as বাস (bus)
        ParsedQuery q = parser.parse("খুলনায় বাসায় যাব", MONDAY);
        assertEquals(TransportType.ALL, q.transportType());
        assertFalse(q.detectedTerms().contains("বাস"));
    }

    @Test
    void latinCityRequiresWordBoundary() {
        // mid-word occurrences of "dhaka" / "ctg" must not match
        ParsedQuery q = parser.parse("dhakactg tickets", MONDAY);
        assertNull(q.source());
        assertNull(q.destination());
    }

    @Test
    void bengaliDigitNormalisationIsOneToOne() {
        assertEquals("2026-11-08", QueryParser.normalizeDigits("২০২৬-১১-০৮"));
        assertEquals("500 taka", QueryParser.normalizeDigits("৫০০ taka"));
        assertEquals(9, QueryParser.normalizeDigits("১২৩৪৫৬৭৮৯").length());
    }

    @Test
    void nextFridayIsStrictlyAfterToday() {
        // reference date itself is a Friday → "আগামী শুক্রবার" means +7 days
        LocalDate friday = LocalDate.of(2026, 11, 6);
        ParsedQuery q = parser.parse("আগামী শুক্রবার ঢাকা থেকে খুলনা", friday);
        assertEquals(DayOfWeek.FRIDAY, q.travelDate().getDayOfWeek());
        assertEquals(friday.plusWeeks(1), q.travelDate());
    }
}
