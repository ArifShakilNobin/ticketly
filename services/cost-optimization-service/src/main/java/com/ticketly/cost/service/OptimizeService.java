package com.ticketly.cost.service;

import com.ticketly.common.dto.cost.OfferResponse;
import com.ticketly.common.dto.cost.OptimizeRequest;
import com.ticketly.common.dto.cost.OptimizeResponse;
import com.ticketly.common.dto.search.FareItem;
import com.ticketly.common.dto.search.OptimizedFare;
import com.ticketly.cost.domain.Offer;
import com.ticketly.cost.repo.OfferRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

/** Orchestrates the pricing pipeline: load the offer catalogue → price → badge → rank → budget. */
@Service
public class OptimizeService {

    private final OfferRepository offers;
    private final EffectivePriceCalculator calculator;

    public OptimizeService(OfferRepository offers, EffectivePriceCalculator calculator) {
        this.offers = offers;
        this.calculator = calculator;
    }

    @Transactional(readOnly = true)
    public OptimizeResponse optimize(OptimizeRequest request) {
        Instant now = Instant.now();
        List<FareItem> fares = request == null || request.items() == null ? List.of() : request.items();
        List<OptimizedFare> ranked = calculator.optimize(
                fares,
                offers.findAll(),
                request == null ? List.of() : request.safePaymentMethods(),
                request == null ? null : request.promoCode(),
                request == null ? null : request.priority(),
                request == null ? null : request.budgetLimit(),
                now);
        // cheapestId is unaffected by the budget filter (it only drops higher priced items);
        // recommendedId is the first fare of the list we actually return.
        String cheapestId = EffectivePriceCalculator.cheapestId(ranked);
        String recommendedId = ranked.isEmpty() ? null : ranked.get(0).fare().id();
        return new OptimizeResponse(ranked, cheapestId, recommendedId, Instant.now());
    }

    /** Offers that are active right now. */
    @Transactional(readOnly = true)
    public List<OfferResponse> activeOffers() {
        Instant now = Instant.now();
        return offers.findAll().stream()
                .filter(offer -> offer.isActive()
                        && (offer.getValidFrom() == null || !now.isBefore(offer.getValidFrom()))
                        && (offer.getValidTo() == null || !now.isAfter(offer.getValidTo())))
                .map(OptimizeService::toResponse)
                .toList();
    }

    private static OfferResponse toResponse(Offer offer) {
        return new OfferResponse(
                String.valueOf(offer.getId()),
                offer.getTitle(),
                offer.getProvider(),
                offer.getCashbackType() == null ? null : offer.getCashbackType().name(),
                offer.getCashbackPercent(),
                offer.getCashbackAmount(),
                offer.getMaxCashback(),
                offer.getMinFare(),
                offer.paymentMethodList(),
                offer.getValidFrom(),
                offer.getValidTo(),
                offer.isActive());
    }
}
