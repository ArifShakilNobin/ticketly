package com.ticketly.cost.service;

import com.ticketly.common.dto.TransportType;
import com.ticketly.common.dto.search.FareItem;
import com.ticketly.common.dto.search.OptimizedFare;
import com.ticketly.common.dto.search.PriceBreakdown;
import com.ticketly.cost.domain.CashbackType;
import com.ticketly.cost.domain.Offer;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Unit tests for the pricing formula — no Spring context, no database.
 */
class EffectivePriceCalculatorTest {

    private static final Instant NOW = Instant.parse("2026-11-07T10:00:00Z");

    private EffectivePriceCalculator calculator;

    @BeforeEach
    void setUp() {
        calculator = new EffectivePriceCalculator(new BigDecimal("20"));
    }

    // ------------------------------------------------------------- spec formula

    @Test
    void exactSpecFormula() {
        // Effective Price = Base Fare − MFS Cashback − Promo Discount + Convenience Fee
        FareItem fare = fare("f1", 120, "1000");
        Offer bkash = percentOffer("bKash 5% cashback", "bKash", "5", "100", "300", "MFS:bKash");

        PriceBreakdown price = calculator.breakdown(fare, bkash, null);

        assertEquals(new BigDecimal("1000.00"), price.baseFare());
        assertEquals(new BigDecimal("50.00"), price.mfsCashback());       // 5% of 1000
        assertEquals(new BigDecimal("0.00"), price.promoDiscount());
        assertEquals(new BigDecimal("20.00"), price.convenienceFee());
        assertEquals(new BigDecimal("970.00"), price.effectivePrice());    // 1000 − 50 − 0 + 20
        assertEquals(new BigDecimal("50.00"), price.savedAmount());       // cashback + promo
    }

    @Test
    void percentCashbackIsCappedByMaxCashback() {
        FareItem fare = fare("f1", 300, "10000");
        Offer ebl = percentOffer("EBL 10% cashback", "EBL", "10", "200", "1000", "CARD:EBL");

        PriceBreakdown price = calculator.breakdown(fare, ebl, null);

        // 10% of 10000 = 1000 but the offer is capped at 200
        assertEquals(new BigDecimal("200.00"), price.mfsCashback());
        assertEquals(new BigDecimal("9820.00"), price.effectivePrice());
        assertEquals(new BigDecimal("200.00"), price.savedAmount());
    }

    @Test
    void flatPromoOfferIsSubtracted() {
        FareItem fare = fare("f1", 240, "500");
        Offer promo = flatPromo("EIDSALE ৳50 off", "50", "400", "EIDSALE");

        PriceBreakdown price = calculator.breakdown(fare, null, promo);

        assertEquals(new BigDecimal("0.00"), price.mfsCashback());
        assertEquals(new BigDecimal("50.00"), price.promoDiscount());
        assertEquals(new BigDecimal("470.00"), price.effectivePrice());   // 500 − 50 + 20
        assertEquals(new BigDecimal("50.00"), price.savedAmount());
    }

    @Test
    void effectivePriceIsClampedAtZero() {
        FareItem fare = fare("f1", 30, "30");
        Offer hugeDiscount = flatPromo("Huge promo", "100", "0", "HUGE");

        PriceBreakdown price = calculator.breakdown(fare, null, hugeDiscount);

        // 30 − 100 + 20 = −50 → clamped at 0.00
        assertEquals(new BigDecimal("0.00"), price.effectivePrice());
        assertTrue(price.effectivePrice().signum() >= 0);
        // savedAmount still reports what the offers gave away
        assertEquals(new BigDecimal("100.00"), price.savedAmount());
    }

    @Test
    void nullFareAndNullOffersYieldZeroBasedBreakdown() {
        PriceBreakdown price = calculator.breakdown(null, null, null);

        assertEquals(new BigDecimal("0.00"), price.baseFare());
        assertEquals(new BigDecimal("0.00"), price.mfsCashback());
        assertEquals(new BigDecimal("0.00"), price.promoDiscount());
        assertEquals(new BigDecimal("20.00"), price.convenienceFee());
        assertEquals(new BigDecimal("20.00"), price.effectivePrice());
        assertEquals(new BigDecimal("0.00"), price.savedAmount());
    }

    // ------------------------------------------------------------- offer selection

    @Test
    void bestCashbackOfferIsChosenAmongSeveral() {
        FareItem fare = fare("f1", 300, "5000");
        Offer bkash = percentOffer("bKash 5% cashback", "bKash", "5", "100", "300", "MFS:bKash");
        Offer nagad = percentOffer("Nagad 4% cashback", "Nagad", "4", "75", "300", "MFS:Nagad");
        Offer ebl = percentOffer("EBL 10% cashback", "EBL", "10", "200", "1000", "CARD:EBL");
        List<Offer> offers = List.of(bkash, nagad, ebl);

        // With both methods requested: bKash caps at 100, EBL caps at 200 → EBL wins.
        Offer best = calculator.bestCashback(offers, fare, List.of("MFS:bKash", "CARD:EBL"), NOW);
        assertEquals("EBL 10% cashback", best.getTitle());
        assertEquals(new BigDecimal("200.00"), calculator.discountFor(best, fare));

        // Restricting the request to bKash removes the better EBL offer.
        Offer onlyBkash = calculator.bestCashback(offers, fare, List.of("MFS:bKash"), NOW);
        assertEquals("bKash 5% cashback", onlyBkash.getTitle());

        // No payment methods requested → "any" → still the best discount overall.
        Offer anyMethod = calculator.bestCashback(offers, fare, List.of(), NOW);
        assertEquals("EBL 10% cashback", anyMethod.getTitle());
    }

    @Test
    void inactiveExpiredAndBelowMinFareOffersAreSkipped() {
        FareItem cheapFare = fare("f1", 120, "250");                 // below minFare 300
        Offer bkash = percentOffer("bKash 5% cashback", "bKash", "5", "100", "300", "MFS:bKash");

        assertNull(calculator.bestCashback(List.of(bkash), cheapFare, List.of("MFS:bKash"), NOW));

        Offer inactive = percentOffer("Nagad 4% cashback", "Nagad", "4", "75", "300", "MFS:Nagad");
        inactive.setActive(false);
        assertNull(calculator.bestCashback(List.of(inactive), fare("f2", 120, "1000"),
                List.of("MFS:Nagad"), NOW));

        Offer expired = percentOffer("Rocket 3% cashback", "Rocket", "3", "50", "200", "MFS:Rocket");
        expired.setValidTo(NOW.minusSeconds(60));
        assertNull(calculator.bestCashback(List.of(expired), fare("f3", 120, "1000"),
                List.of("MFS:Rocket"), NOW));
    }

    @Test
    void promoCodeMatchesCaseInsensitivelyAndRespectsMinFare() {
        FareItem fare = fare("f1", 240, "500");
        Offer promo = flatPromo("EIDSALE ৳50 off", "50", "400", "EIDSALE");

        assertEquals(promo, calculator.matchingPromo(List.of(promo), fare, List.of(), "eidsale", NOW));
        assertNull(calculator.matchingPromo(List.of(promo), fare, List.of(), "OTHER", NOW));
        assertNull(calculator.matchingPromo(List.of(promo), fare, List.of(), null, NOW));

        // base fare 350 < minFare 400 → the promo does not apply
        FareItem tooCheap = fare("f2", 240, "350");
        assertNull(calculator.matchingPromo(List.of(promo), tooCheap, List.of(), "EIDSALE", NOW));
    }

    // ------------------------------------------------------------- badges

    @Test
    void badgesMarkCheapestFastestAndBestValue() {
        // A: expensive & medium, B: cheapest & slow, C: medium & fastest → best value (৳/min)
        List<OptimizedFare> fares = List.of(
                priced(fare("A", 120, "1000")),
                priced(fare("B", 180, "800")),
                priced(fare("C", 90, "900")));

        List<String> badges = EffectivePriceCalculator.badges(fares);

        assertEquals("", badges.get(0));                            // A: neither cheapest nor fastest
        // 820/180 = 4.56 ৳/min is the best price-per-minute ratio
        assertEquals("CHEAPEST, BEST VALUE", badges.get(1));
        assertEquals("FASTEST", badges.get(2));                      // 90 minutes, but 10.22 ৳/min
    }

    // ------------------------------------------------------------- ranking

    @Test
    void rankByCheapestThenFastestThenBalanced() {
        List<OptimizedFare> fares = List.of(
                priced(fare("A", 120, "1000")),
                priced(fare("B", 180, "800")),
                priced(fare("C", 90, "900")));

        assertEquals(List.of("B", "C", "A"), ids(EffectivePriceCalculator.rank(fares, "CHEAPEST")));
        assertEquals(List.of("C", "A", "B"), ids(EffectivePriceCalculator.rank(fares, "FASTEST")));

        // BALANCED: score = 0.6·normPrice + 0.4·normDuration
        //   A: 0.6·1.00 + 0.4·0.33 = 0.733   B: 0.6·0.00 + 0.4·1.00 = 0.400   C: 0.6·0.50 + 0.4·0.00 = 0.300
        assertEquals(List.of("C", "B", "A"), ids(EffectivePriceCalculator.rank(fares, "BALANCED")));
        // null / blank priority falls back to BALANCED
        assertEquals(List.of("C", "B", "A"), ids(EffectivePriceCalculator.rank(fares, null)));
        assertEquals(List.of("C", "B", "A"), ids(EffectivePriceCalculator.rank(fares, "  ")));
    }

    @Test
    void cheapestRankBreaksTiesByDuration() {
        List<OptimizedFare> fares = List.of(
                priced(fare("SLOW", 180, "500")),
                priced(fare("FAST", 90, "500")));

        assertEquals(List.of("FAST", "SLOW"), ids(EffectivePriceCalculator.rank(fares, "CHEAPEST")));
        assertEquals("SLOW", EffectivePriceCalculator.cheapestId(fares)); // first min wins
    }

    // ------------------------------------------------------------- budget

    @Test
    void budgetDropsFaresOverTheLimitButKeepsOrder() {
        List<OptimizedFare> ranked = EffectivePriceCalculator.rank(List.of(
                priced(fare("A", 120, "500")),
                priced(fare("B", 120, "700")),
                priced(fare("C", 120, "900"))), "CHEAPEST");

        List<OptimizedFare> within = EffectivePriceCalculator.applyBudget(ranked, new BigDecimal("800"));
        assertEquals(List.of("A", "B"), ids(within));

        // no limit (null or zero) → everything is kept
        assertEquals(3, EffectivePriceCalculator.applyBudget(ranked, null).size());
        assertEquals(3, EffectivePriceCalculator.applyBudget(ranked, BigDecimal.ZERO).size());
    }

    @Test
    void budgetThatExcludesEverythingReturnsTheFullRankedList() {
        List<OptimizedFare> ranked = EffectivePriceCalculator.rank(List.of(
                priced(fare("A", 120, "500")),
                priced(fare("B", 120, "700"))), "CHEAPEST");

        List<OptimizedFare> result = EffectivePriceCalculator.applyBudget(ranked, new BigDecimal("100"));

        // Not an empty result: the full ranked list comes back instead (documented behaviour).
        assertEquals(2, result.size());
        assertEquals(List.of("A", "B"), ids(result));
    }

    // ------------------------------------------------------------- pipeline

    @Test
    void optimizePipelinePricesBadgesRanksAndFilters() {
        FareItem cheap = fare("cheap", 180, "800");
        FareItem fast = fare("fast", 90, "1200");
        Offer bkash = percentOffer("bKash 5% cashback", "bKash", "5", "100", "300", "MFS:bKash");

        List<OptimizedFare> result = calculator.optimize(
                List.of(cheap, fast), List.of(bkash), List.of("MFS:bKash"), null,
                "CHEAPEST", null, NOW);

        assertEquals(2, result.size());
        OptimizedFare cheapResult = result.get(0);
        assertEquals("cheap", cheapResult.fare().id());
        assertEquals(new BigDecimal("40.00"), cheapResult.price().mfsCashback());   // 5% of 800
        assertEquals(new BigDecimal("780.00"), cheapResult.price().effectivePrice());
        assertEquals(List.of("bKash 5% cashback"), cheapResult.appliedOffers());
        assertEquals("CHEAPEST, BEST VALUE", cheapResult.badge());
    }

    @Test
    void optimizeWithEmptyItemsReturnsEmptyResult() {
        assertTrue(calculator.optimize(null, List.of(), List.of(), null, null, null, NOW).isEmpty());
        assertTrue(calculator.optimize(List.of(), List.of(), List.of(), null, null, null, NOW).isEmpty());
    }

    @Test
    void optimizeAppliesPromoAndBudgetTogether() {
        FareItem promoFare = fare("promoFare", 240, "500");
        FareItem plainFare = fare("plainFare", 240, "900");
        Offer promo = flatPromo("WELCOME20 ৳20 off", "20", "200", "WELCOME20");

        List<OptimizedFare> result = calculator.optimize(
                List.of(plainFare, promoFare), List.of(promo), List.of(), "welcome20",
                "CHEAPEST", new BigDecimal("500"), NOW);

        // 500 − 20 + 20 = 500 is within budget, 900 is not → only the promo fare survives
        assertEquals(List.of("promoFare"), ids(result));
        assertEquals(new BigDecimal("20.00"), result.get(0).price().promoDiscount());
        assertEquals(List.of("WELCOME20 ৳20 off"), result.get(0).appliedOffers());
    }

    // ------------------------------------------------------------- helpers

    private static FareItem fare(String id, int durationMins, String baseFare) {
        return new FareItem(id, "TestOperator", "ref-" + id, TransportType.BUS,
                "Dhaka", "Chittagong", LocalDate.of(2026, 12, 1),
                LocalTime.of(8, 0), LocalTime.of(14, 0), durationMins,
                new BigDecimal(baseFare), "BDT", 40, "AC", "non-refundable", Map.of());
    }

    private static OptimizedFare priced(FareItem fare) {
        PriceBreakdown price = new PriceBreakdown(
                fare.baseFare(), new BigDecimal("0.00"), new BigDecimal("0.00"),
                new BigDecimal("20.00"),
                EffectivePriceCalculator.money(fare.baseFare().add(new BigDecimal("20"))),
                new BigDecimal("0.00"));
        return new OptimizedFare(fare, price, List.of(), "");
    }

    private static Offer percentOffer(String title, String provider, String percent,
                                      String maxCashback, String minFare, String methods) {
        Offer offer = new Offer();
        offer.setTitle(title);
        offer.setProvider(provider);
        offer.setCashbackType(CashbackType.PERCENT);
        offer.setCashbackPercent(new BigDecimal(percent));
        offer.setMaxCashback(new BigDecimal(maxCashback));
        offer.setMinFare(new BigDecimal(minFare));
        offer.setPaymentMethods(methods);
        offer.setValidFrom(NOW.minusSeconds(3600));
        offer.setValidTo(NOW.plusSeconds(86400));
        offer.setActive(true);
        return offer;
    }

    private static Offer flatPromo(String title, String amount, String minFare, String promoCode) {
        Offer offer = new Offer();
        offer.setTitle(title);
        offer.setProvider("PROMO");
        offer.setCashbackType(CashbackType.FLAT);
        offer.setCashbackAmount(new BigDecimal(amount));
        offer.setMinFare(new BigDecimal(minFare));
        offer.setPaymentMethods("");
        offer.setValidFrom(NOW.minusSeconds(3600));
        offer.setValidTo(NOW.plusSeconds(86400));
        offer.setActive(true);
        offer.setPromoCode(promoCode);
        return offer;
    }

    private static List<String> ids(List<OptimizedFare> fares) {
        return fares.stream().map(f -> f.fare().id()).toList();
    }
}
