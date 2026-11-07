package com.ticketly.cost.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;

/**
 * An MFS cashback, bank cashback or promo-code offer from the catalogue.
 *
 * <p>{@code paymentMethods} is stored comma separated, e.g. {@code "MFS:bKash"} or {@code "CARD:EBL"};
 * blank means the offer is not restricted to any payment method.</p>
 */
@Entity
@Table(name = "offers")
public class Offer {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 160)
    private String title;

    /** bKash / Nagad / Rocket / EBL / BRAC / PROMO */
    @Column(nullable = false, length = 40)
    private String provider;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private CashbackType cashbackType;

    @Column(precision = 8, scale = 2)
    private BigDecimal cashbackPercent;

    @Column(precision = 12, scale = 2)
    private BigDecimal cashbackAmount;

    /** Upper bound for PERCENT offers, e.g. "max 100 BDT". */
    @Column(precision = 12, scale = 2)
    private BigDecimal maxCashback;

    /** Minimum base fare for the offer to apply. */
    @Column(precision = 12, scale = 2)
    private BigDecimal minFare;

    /** Comma separated payment method codes; blank = any. */
    @Column(length = 200)
    private String paymentMethods;

    private Instant validFrom;

    private Instant validTo;

    @Column(nullable = false)
    private boolean active = true;

    /** Set only for promo-code offers (provider {@code PROMO}). */
    @Column(length = 40)
    private String promoCode;

    public Offer() {
    }

    /** The offer's payment methods as a trimmed list; empty when unrestricted. */
    public List<String> paymentMethodList() {
        if (paymentMethods == null || paymentMethods.isBlank()) {
            return List.of();
        }
        return Arrays.stream(paymentMethods.split(","))
                .map(String::trim)
                .filter(value -> !value.isEmpty())
                .toList();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getProvider() {
        return provider;
    }

    public void setProvider(String provider) {
        this.provider = provider;
    }

    public CashbackType getCashbackType() {
        return cashbackType;
    }

    public void setCashbackType(CashbackType cashbackType) {
        this.cashbackType = cashbackType;
    }

    public BigDecimal getCashbackPercent() {
        return cashbackPercent;
    }

    public void setCashbackPercent(BigDecimal cashbackPercent) {
        this.cashbackPercent = cashbackPercent;
    }

    public BigDecimal getCashbackAmount() {
        return cashbackAmount;
    }

    public void setCashbackAmount(BigDecimal cashbackAmount) {
        this.cashbackAmount = cashbackAmount;
    }

    public BigDecimal getMaxCashback() {
        return maxCashback;
    }

    public void setMaxCashback(BigDecimal maxCashback) {
        this.maxCashback = maxCashback;
    }

    public BigDecimal getMinFare() {
        return minFare;
    }

    public void setMinFare(BigDecimal minFare) {
        this.minFare = minFare;
    }

    public String getPaymentMethods() {
        return paymentMethods;
    }

    public void setPaymentMethods(String paymentMethods) {
        this.paymentMethods = paymentMethods;
    }

    public Instant getValidFrom() {
        return validFrom;
    }

    public void setValidFrom(Instant validFrom) {
        this.validFrom = validFrom;
    }

    public Instant getValidTo() {
        return validTo;
    }

    public void setValidTo(Instant validTo) {
        this.validTo = validTo;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    public String getPromoCode() {
        return promoCode;
    }

    public void setPromoCode(String promoCode) {
        this.promoCode = promoCode;
    }
}
