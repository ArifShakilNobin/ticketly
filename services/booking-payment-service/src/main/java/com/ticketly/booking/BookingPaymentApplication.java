package com.ticketly.booking;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/** Create bookings, take payment (mock gateway) and emit booking events. */
@SpringBootApplication(scanBasePackages = "com.ticketly")
public class BookingPaymentApplication {

    public static void main(String[] args) {
        SpringApplication.run(BookingPaymentApplication.class, args);
    }
}
