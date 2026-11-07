package com.ticketly.cost.config;

import com.ticketly.cost.domain.CashbackType;
import com.ticketly.cost.domain.Offer;
import com.ticketly.cost.repo.OfferRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;

/**
 * Seeds the realistic BDT offer catalogue when the {@code offers} table is empty.
 * All validity windows are relative to {@code Instant.now()} so the offers are always active.
 */
@Configuration
public class OfferSeeder {

    private static final Logger log = LoggerFactory.getLogger(OfferSeeder.class);

    private final OfferRepository offers;

    public OfferSeeder(OfferRepository offers) {
        this.offers = offers;
    }

    @Bean
    public CommandLineRunner seedOffers() {
        return args -> {
            if (offers.count() > 0) {
                return;
            }
            Instant now = Instant.now();
            Instant from = now.minus(Duration.ofDays(1));

            // MFS / bank cashbacks (PERCENT, capped)
            offers.save(cashback("bKash 5% cashback", "bKash", "5", "100", "300", "MFS:bKash", from, now.plus(Duration.ofDays(365))));
            offers.save(cashback("Nagad 4% cashback", "Nagad", "4", "75", "300", "MFS:Nagad", from, now.plus(Duration.ofDays(365))));
            offers.save(cashback("Rocket 3% cashback", "Rocket", "3", "50", "200", "MFS:Rocket", from, now.plus(Duration.ofDays(365))));
            offers.save(cashback("EBL Visa/Mastercard 10% cashback", "EBL", "10", "200", "1000", "CARD:EBL", from, now.plus(Duration.ofDays(365))));
            offers.save(cashback("BRAC Bank 7% cashback", "BRAC", "7", "150", "800", "CARD:BRAC", from, now.plus(Duration.ofDays(365))));

            // Promo codes (FLAT)
            offers.save(promo("EIDSALE ৳50 off", "50", "400", "EIDSALE", from, now.plus(Duration.ofDays(90))));
            offers.save(promo("WELCOME20 ৳20 off", "20", "200", "WELCOME20", from, now.plus(Duration.ofDays(365))));

            log.info("Seeded {} offers into the catalogue", offers.count());
        };
    }

    private static Offer cashback(String title, String provider, String percent, String maxCashback,
                                  String minFare, String paymentMethods, Instant validFrom, Instant validTo) {
        Offer offer = new Offer();
        offer.setTitle(title);
        offer.setProvider(provider);
        offer.setCashbackType(CashbackType.PERCENT);
        offer.setCashbackPercent(new BigDecimal(percent));
        offer.setMaxCashback(new BigDecimal(maxCashback));
        offer.setMinFare(new BigDecimal(minFare));
        offer.setPaymentMethods(paymentMethods);
        offer.setValidFrom(validFrom);
        offer.setValidTo(validTo);
        offer.setActive(true);
        return offer;
    }

    private static Offer promo(String title, String amount, String minFare, String promoCode,
                               Instant validFrom, Instant validTo) {
        Offer offer = new Offer();
        offer.setTitle(title);
        offer.setProvider("PROMO");
        offer.setCashbackType(CashbackType.FLAT);
        offer.setCashbackAmount(new BigDecimal(amount));
        offer.setMinFare(new BigDecimal(minFare));
        offer.setPaymentMethods(""); // any payment method
        offer.setValidFrom(validFrom);
        offer.setValidTo(validTo);
        offer.setActive(true);
        offer.setPromoCode(promoCode);
        return offer;
    }
}
