package com.ticketly.cost.config;

import com.ticketly.cost.service.EffectivePriceCalculator;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.math.BigDecimal;

@Configuration
public class CostConfig {

    /**
     * The pricing calculator is a plain object (no Spring annotations inside) so it can be unit
     * tested without a context; it is wired here with the configured convenience fee.
     */
    @Bean
    public EffectivePriceCalculator effectivePriceCalculator(
            @Value("${cost.convenience-fee:20}") BigDecimal convenienceFee) {
        return new EffectivePriceCalculator(convenienceFee);
    }
}
