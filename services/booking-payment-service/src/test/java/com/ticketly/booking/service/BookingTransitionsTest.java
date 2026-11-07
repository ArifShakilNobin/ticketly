package com.ticketly.booking.service;

import com.ticketly.common.dto.BookingStatus;
import com.ticketly.common.web.ApiException;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class BookingTransitionsTest {

    @Test
    void cancelFromConfirmedWorks() {
        assertEquals(BookingStatus.CANCELLED, BookingTransitions.cancel(BookingStatus.CONFIRMED));
        assertTrue(BookingTransitions.canCancel(BookingStatus.CONFIRMED));
    }

    @Test
    void cancelFromPendingWorks() {
        assertEquals(BookingStatus.CANCELLED, BookingTransitions.cancel(BookingStatus.PENDING));
        assertTrue(BookingTransitions.canCancel(BookingStatus.PENDING));
    }

    @Test
    void cancelFromCancelledIsAConflict() {
        ApiException ex = assertThrows(ApiException.class,
                () -> BookingTransitions.cancel(BookingStatus.CANCELLED));

        assertEquals(409, ex.getStatus());
        assertEquals("conflict", ex.getCode());
        assertFalse(BookingTransitions.canCancel(BookingStatus.CANCELLED));
    }

    @Test
    void cancelFromFailedIsAConflict() {
        ApiException ex = assertThrows(ApiException.class,
                () -> BookingTransitions.cancel(BookingStatus.FAILED));

        assertEquals(409, ex.getStatus());
        assertFalse(BookingTransitions.canCancel(BookingStatus.FAILED));
    }
}
