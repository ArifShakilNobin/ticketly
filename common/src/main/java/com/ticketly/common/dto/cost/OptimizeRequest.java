package com.ticketly.common.dto.cost;

import com.ticketly.common.dto.search.FareItem;

import java.math.BigDecimal;
import java.util.List;

/** Input of the cost optimisation engine: raw fares plus the user's payment/preference hints. */
public record OptimizeRequest(
        List<FareItem> items,
        List<String> paymentMethods,
        String priority,
        BigDecimal budgetLimit,
        String promoCode) {

    public List<String> safePaymentMethods() {
        return paymentMethods == null || paymentMethods.isEmpty() ? List.of() : paymentMethods;
    }
}
