package com.ticketly.booking.service;

import java.security.SecureRandom;

/**
 * PNR generator: {@code TK} followed by 6 uppercase alphanumerics (e.g. {@code TK7H2QX9}).
 * Uses a {@link SecureRandom} so PNRs are unpredictable; {@link #generate()} has no practical
 * collision risk for this platform, and callers additionally check the database for uniqueness.
 */
public final class PnrGenerator {

    private static final String PREFIX = "TK";
    private static final int RANDOM_LENGTH = 6;
    private static final char[] ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".toCharArray();
    private static final SecureRandom RANDOM = new SecureRandom();

    private PnrGenerator() {
    }

    /** A fresh PNR matching {@code ^TK[A-Z0-9]{6}$}. */
    public static String generate() {
        StringBuilder pnr = new StringBuilder(PREFIX);
        for (int i = 0; i < RANDOM_LENGTH; i++) {
            pnr.append(ALPHABET[RANDOM.nextInt(ALPHABET.length)]);
        }
        return pnr.toString();
    }

    /** The {@code TK} prefix shared by every Ticketly PNR. */
    public static String prefix() {
        return PREFIX;
    }
}
