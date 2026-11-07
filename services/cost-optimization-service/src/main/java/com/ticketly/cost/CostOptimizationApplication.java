package com.ticketly.cost;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/** Pricing formula and offer catalogue: {@code /api/v1/optimize} and {@code /api/v1/offers}. */
@SpringBootApplication(scanBasePackages = "com.ticketly")
public class CostOptimizationApplication {

    public static void main(String[] args) {
        SpringApplication.run(CostOptimizationApplication.class, args);
    }
}
