package com.ticketly.cost.service;

import com.ticketly.common.dto.search.FareItem;
import com.ticketly.common.dto.search.OptimizedFare;
import com.ticketly.common.dto.search.PriceBreakdown;
import com.ticketly.cost.domain.CashbackType;
import com.ticketly.cost.domain.Offer;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;

/**
 * Single source of truth for the Ticketly pricing formula (all money in BDT, scale 2):
 *
 * <pre>
 * Effective Price = Base Fare − MFS Cashback − Promo Discount + Convenience Fee
 * </pre>
 *
 * <p>The effective price is never negative: it is clamped at {@code 0.00}. This class is pure
 * domain logic — no Spring, no database — so the whole formula can be unit tested directly.</p>
 */
public class EffectivePriceCalculator {

    public static final String PRIORITY_CHEAPEST = "CHEAPEST";
    public static final String PRIORITY_FASTEST = "FASTEST";
    public static final String PRIORITY_BALANCED = "BALANCED";

    public static final String BADGE_CHEAPEST = "CHEAPEST";
    public static final String BADGE_FASTEST = "FASTEST";
    public static final String BADGE_BEST_VALUE = "BEST VALUE";

    public static final BigDecimal ZERO = new BigDecimal("0.00");

    /** BALANCED score = 0.6 × normalised price + 0.4 × normalised duration (lower is better). */
    private static final BigDecimal PRICE_WEIGHT = new BigDecimal("0.6");
    private static final BigDecimal DURATION_WEIGHT = new BigDecimal("0.4");

    private final BigDecimal convenienceFee;

    public EffectivePriceCalculator(BigDecimal convenienceFee) {
        this.convenienceFee = money(convenienceFee == null ? new BigDecimal("20") : convenienceFee);
    }

    public BigDecimal convenienceFee() {
        return convenienceFee;
    }

    /** Normalises any monetary value to scale 2 ({@code null} → {@code 0.00}). */
    public static BigDecimal money(BigDecimal value) {
        return value == null ? ZERO : value.setScale(2, RoundingMode.HALF_UP);
    }

    // ------------------------------------------------------------------ offers

    /**
     * Discount a single offer yields for the fare. PERCENT offers are capped by
     * {@code maxCashback}; FLAT offers give their fixed amount.
     */
    public BigDecimal discountFor(Offer offer, FareItem fare) {
        if (offer == null || offer.getCashbackType() == null) {
            return ZERO;
        }
        BigDecimal discount;
        if (offer.getCashbackType() == CashbackType.PERCENT) {
            BigDecimal percent = offer.getCashbackPercent() == null ? ZERO : offer.getCashbackPercent();
            BigDecimal baseFare = fare == null || fare.baseFare() == null ? ZERO : fare.baseFare();
            discount = baseFare.multiply(percent).divide(new BigDecimal("100"), 2, RoundingMode.HALF_UP);
            BigDecimal cap = offer.getMaxCashback();
            if (cap != null && discount.compareTo(cap) > 0) {
                discount = cap;
            }
        } else {
            discount = offer.getCashbackAmount() == null ? ZERO : offer.getCashbackAmount();
        }
        return money(discount.max(ZERO));
    }

    /**
     * Applicability: active AND {@code now ∈ [validFrom, validTo]} AND {@code baseFare ≥ minFare}
     * AND the offer's payment methods intersect the requested ones (an empty request means "any").
     */
    public boolean applies(Offer offer, FareItem fare, List<String> paymentMethods, Instant now) {
        if (offer == null || !offer.isActive()) {
            return false;
        }
        Instant at = now == null ? Instant.now() : now;
        if (offer.getValidFrom() != null && at.isBefore(offer.getValidFrom())) {
            return false;
        }
        if (offer.getValidTo() != null && at.isAfter(offer.getValidTo())) {
            return false;
        }
        BigDecimal baseFare = fare == null || fare.baseFare() == null ? ZERO : fare.baseFare();
        if (offer.getMinFare() != null && baseFare.compareTo(offer.getMinFare()) < 0) {
            return false;
        }
        return paymentMethodsMatch(offer, paymentMethods);
    }

    private boolean paymentMethodsMatch(Offer offer, List<String> paymentMethods) {
        List<String> requested = paymentMethods == null ? List.of() : paymentMethods;
        if (requested.isEmpty()) {
            return true; // caller did not restrict the method → any method is fine
        }
        List<String> offered = offer.paymentMethodList();
        if (offered.isEmpty()) {
            return true; // the offer itself is not method specific
        }
        for (String want : requested) {
            if (want == null || want.isBlank()) {
                continue;
            }
            for (String have : offered) {
                if (have.equalsIgnoreCase(want)) {
                    return true;
                }
                // a request for "MFS" also matches an offer restricted to "MFS:bKash"
                if (have.length() > want.length()
                        && have.regionMatches(true, 0, want, 0, want.length())
                        && have.charAt(want.length()) == ':') {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * The single best cashback (largest discount for this fare, percent offers capped) among the
     * applicable non-promo offers; {@code null} when nothing applies. Promo offers are excluded —
     * they are selected separately through {@link #matchingPromo}.
     */
    public Offer bestCashback(List<Offer> offers, FareItem fare, List<String> paymentMethods, Instant now) {
        Offer best = null;
        BigDecimal bestDiscount = ZERO;
        for (Offer offer : offers == null ? List.<Offer>of() : offers) {
            if (offer.getPromoCode() != null && !offer.getPromoCode().isBlank()) {
                continue;
            }
            if (!applies(offer, fare, paymentMethods, now)) {
                continue;
            }
            BigDecimal discount = discountFor(offer, fare);
            if (best == null || discount.compareTo(bestDiscount) > 0) {
                best = offer;
                bestDiscount = discount;
            }
        }
        return best;
    }

    /** The promo offer whose code equals {@code promoCode} (case-insensitive) and applies; else {@code null}. */
    public Offer matchingPromo(List<Offer> offers, FareItem fare, List<String> paymentMethods,
                               String promoCode, Instant now) {
        if (promoCode == null || promoCode.isBlank()) {
            return null;
        }
        String wanted = promoCode.trim();
        for (Offer offer : offers == null ? List.<Offer>of() : offers) {
            if (offer.getPromoCode() == null || !offer.getPromoCode().equalsIgnoreCase(wanted)) {
                continue;
            }
            if (applies(offer, fare, paymentMethods, now)) {
                return offer;
            }
        }
        return null;
    }

    // ------------------------------------------------------------------ formula

    /**
     * The spec formula:
     * {@code effectivePrice = max(0, baseFare − mfsCashback − promoDiscount + convenienceFee)},
     * scale 2, clamped at 0.00. {@code savedAmount = mfsCashback + promoDiscount} — the convenience
     * fee is a cost, not a saving.
     */
    public PriceBreakdown breakdown(FareItem fare, Offer cashbackOffer, Offer promoOffer) {
        BigDecimal baseFare = money(fare == null ? null : fare.baseFare());
        BigDecimal cashback = cashbackOffer == null ? ZERO : discountFor(cashbackOffer, fare);
        BigDecimal promo = promoOffer == null ? ZERO : discountFor(promoOffer, fare);
        BigDecimal effective = baseFare.subtract(cashback).subtract(promo).add(convenienceFee);
        if (effective.signum() < 0) {
            effective = ZERO; // never negative → clamp at 0.00
        }
        BigDecimal saved = money(cashback.add(promo));
        return new PriceBreakdown(baseFare, cashback, promo, convenienceFee, money(effective), saved);
    }

    /** Human readable titles of the offers that actually reduced this fare. */
    public static List<String> appliedOfferTitles(PriceBreakdown price, Offer cashbackOffer, Offer promoOffer) {
        List<String> titles = new ArrayList<>();
        if (cashbackOffer != null && price.mfsCashback().compareTo(ZERO) > 0) {
            titles.add(cashbackOffer.getTitle());
        }
        if (promoOffer != null && price.promoDiscount().compareTo(ZERO) > 0) {
            titles.add(promoOffer.getTitle());
        }
        return titles;
    }

    // ------------------------------------------------------------------ pipeline

    /**
     * Prices every fare, badges the set, ranks it by {@code priority} and applies the budget filter.
     * An empty/missing fare list simply yields an empty result.
     */
    public List<OptimizedFare> optimize(List<FareItem> fares, List<Offer> offers,
                                        List<String> paymentMethods, String promoCode,
                                        String priority, BigDecimal budgetLimit, Instant now) {
        List<FareItem> input = fares == null ? List.of() : fares;
        List<OptimizedFare> priced = new ArrayList<>();
        for (FareItem fare : input) {
            if (fare == null) {
                continue;
            }
            Offer cashback = bestCashback(offers, fare, paymentMethods, now);
            Offer promo = matchingPromo(offers, fare, paymentMethods, promoCode, now);
            PriceBreakdown price = breakdown(fare, cashback, promo);
            priced.add(new OptimizedFare(fare, price, appliedOfferTitles(price, cashback, promo), ""));
        }
        List<String> badges = badges(priced);
        List<OptimizedFare> badged = new ArrayList<>(priced.size());
        for (int i = 0; i < priced.size(); i++) {
            OptimizedFare fare = priced.get(i);
            badged.add(new OptimizedFare(fare.fare(), fare.price(), fare.appliedOffers(), badges.get(i)));
        }
        return applyBudget(rank(badged, priority), budgetLimit);
    }

    /**
     * Badges across the whole set: {@code CHEAPEST} for the lowest effective price, {@code FASTEST}
     * for the shortest duration and {@code BEST VALUE} for the best effective-price-per-minute ratio.
     * A fare may carry several; they are joined with ", ". Result is aligned with the input list.
     */
    public static List<String> badges(List<OptimizedFare> fares) {
        List<String> result = new ArrayList<>(Collections.nCopies(fares == null ? 0 : fares.size(), ""));
        if (fares == null || fares.isEmpty()) {
            return result;
        }
        BigDecimal minPrice = null;
        BigDecimal minRatio = null;
        int minDuration = Integer.MAX_VALUE;
        for (OptimizedFare fare : fares) {
            BigDecimal price = fare.price().effectivePrice();
            if (minPrice == null || price.compareTo(minPrice) < 0) {
                minPrice = price;
            }
            int duration = duration(fare);
            if (duration < minDuration) {
                minDuration = duration;
            }
            BigDecimal ratio = pricePerMinute(price, duration);
            if (ratio != null && (minRatio == null || ratio.compareTo(minRatio) < 0)) {
                minRatio = ratio;
            }
        }
        for (int i = 0; i < fares.size(); i++) {
            OptimizedFare fare = fares.get(i);
            List<String> own = new ArrayList<>(3);
            if (fare.price().effectivePrice().compareTo(minPrice) == 0) {
                own.add(BADGE_CHEAPEST);
            }
            if (duration(fare) == minDuration) {
                own.add(BADGE_FASTEST);
            }
            BigDecimal ratio = pricePerMinute(fare.price().effectivePrice(), duration(fare));
            if (ratio != null && minRatio != null && ratio.compareTo(minRatio) == 0) {
                own.add(BADGE_BEST_VALUE);
            }
            result.set(i, String.join(", ", own));
        }
        return result;
    }

    /**
     * Ranking by priority:
     * <ul>
     *   <li>CHEAPEST → effective price asc (tie: duration asc)</li>
     *   <li>FASTEST → duration asc (tie: price asc)</li>
     *   <li>BALANCED (and any unknown/blank value) → 0.6·normalisedPrice + 0.4·normalisedDuration asc</li>
     * </ul>
     */
    public static List<OptimizedFare> rank(List<OptimizedFare> fares, String priority) {
        List<OptimizedFare> ranked = new ArrayList<>(fares);
        String normalized = priority == null ? "" : priority.trim().toUpperCase(Locale.ROOT);
        switch (normalized) {
            case PRIORITY_CHEAPEST -> ranked.sort(Comparator
                    .comparing((OptimizedFare fare) -> fare.price().effectivePrice())
                    .thenComparingInt(EffectivePriceCalculator::duration));
            case PRIORITY_FASTEST -> ranked.sort(Comparator
                    .comparingInt(EffectivePriceCalculator::duration)
                    .thenComparing((OptimizedFare fare) -> fare.price().effectivePrice()));
            default -> {
                Norm norm = Norm.of(ranked);
                ranked.sort(Comparator
                        .comparing((OptimizedFare fare) -> score(fare, norm))
                        .thenComparing((OptimizedFare fare) -> fare.price().effectivePrice()));
            }
        }
        return ranked;
    }

    /**
     * Keeps only fares at or under the budget.
     *
     * <p><b>Budget note:</b> when the limit would drop <i>every</i> fare we deliberately return the
     * full ranked list instead of an empty one — an empty list would look like "there are no fares
     * at all" and is far less useful than the complete ranking. Because nothing is filtered in that
     * case, no budget annotation is applied to the result either.</p>
     */
    public static List<OptimizedFare> applyBudget(List<OptimizedFare> ranked, BigDecimal budgetLimit) {
        if (budgetLimit == null || budgetLimit.signum() <= 0) {
            return ranked;
        }
        List<OptimizedFare> withinBudget = new ArrayList<>();
        for (OptimizedFare fare : ranked) {
            if (fare.price().effectivePrice().compareTo(budgetLimit) <= 0) {
                withinBudget.add(fare);
            }
        }
        return withinBudget.isEmpty() ? ranked : withinBudget;
    }

    /** id of the lowest effective price in the list (first wins ties); {@code null} when empty. */
    public static String cheapestId(List<OptimizedFare> fares) {
        OptimizedFare cheapest = null;
        for (OptimizedFare fare : fares) {
            if (cheapest == null || fare.price().effectivePrice().compareTo(cheapest.price().effectivePrice()) < 0) {
                cheapest = fare;
            }
        }
        return cheapest == null ? null : cheapest.fare().id();
    }

    // ------------------------------------------------------------------ helpers

    private static int duration(OptimizedFare fare) {
        return fare.fare() == null || fare.fare().durationMins() < 0 ? 0 : fare.fare().durationMins();
    }

    /** Effective price per minute; {@code null} when the duration is not positive. */
    private static BigDecimal pricePerMinute(BigDecimal price, int durationMins) {
        if (durationMins <= 0) {
            return null;
        }
        return price.divide(BigDecimal.valueOf(durationMins), 4, RoundingMode.HALF_UP);
    }

    private static BigDecimal score(OptimizedFare fare, Norm norm) {
        BigDecimal normalisedPrice = norm.normalize(
                fare.price().effectivePrice(), norm.minPrice(), norm.maxPrice());
        BigDecimal normalisedDuration = norm.normalize(
                BigDecimal.valueOf(duration(fare)),
                BigDecimal.valueOf(norm.minDuration()),
                BigDecimal.valueOf(norm.maxDuration()));
        return normalisedPrice.multiply(PRICE_WEIGHT).add(normalisedDuration.multiply(DURATION_WEIGHT));
    }

    /** Min/max of the set used to normalise the BALANCED score. */
    private record Norm(BigDecimal minPrice, BigDecimal maxPrice, int minDuration, int maxDuration) {

        static Norm of(List<OptimizedFare> fares) {
            BigDecimal minPrice = null;
            BigDecimal maxPrice = null;
            int minDuration = Integer.MAX_VALUE;
            int maxDuration = Integer.MIN_VALUE;
            for (OptimizedFare fare : fares) {
                BigDecimal price = fare.price().effectivePrice();
                if (minPrice == null || price.compareTo(minPrice) < 0) {
                    minPrice = price;
                }
                if (maxPrice == null || price.compareTo(maxPrice) > 0) {
                    maxPrice = price;
                }
                int duration = duration(fare);
                minDuration = Math.min(minDuration, duration);
                maxDuration = Math.max(maxDuration, duration);
            }
            return new Norm(minPrice, maxPrice, minDuration, maxDuration);
        }

        BigDecimal normalize(BigDecimal value, BigDecimal min, BigDecimal max) {
            if (min == null || max == null || max.compareTo(min) == 0) {
                return BigDecimal.ZERO; // no spread → contributes nothing
            }
            return value.subtract(min).divide(max.subtract(min), 6, RoundingMode.HALF_UP);
        }
    }
}
