package com.ticketly.booking.domain;

import com.ticketly.common.dto.search.PriceBreakdown;

/** Stores the authoritative {@link PriceBreakdown} as a JSON {@code text} column. */
public class PriceJsonConverter extends JsonColumnConverter<PriceBreakdown> {

    public PriceJsonConverter() {
        super(PriceBreakdown.class);
    }
}
