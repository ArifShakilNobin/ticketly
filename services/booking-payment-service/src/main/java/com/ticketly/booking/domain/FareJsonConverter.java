package com.ticketly.booking.domain;

import com.ticketly.common.dto.search.FareItem;

/** Stores the booked {@link FareItem} as a JSON {@code text} column. */
public class FareJsonConverter extends JsonColumnConverter<FareItem> {

    public FareJsonConverter() {
        super(FareItem.class);
    }
}
