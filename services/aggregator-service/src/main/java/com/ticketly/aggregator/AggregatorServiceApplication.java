package com.ticketly.aggregator;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/** Queries transport providers in parallel, caches and optimises the result. */
@SpringBootApplication(scanBasePackages = "com.ticketly")
public class AggregatorServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(AggregatorServiceApplication.class, args);
    }
}
