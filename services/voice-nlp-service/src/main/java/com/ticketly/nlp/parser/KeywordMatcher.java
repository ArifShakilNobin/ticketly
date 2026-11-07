package com.ticketly.nlp.parser;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;

/**
 * Small, dependency-free keyword scanner shared by every parsing rule.
 *
 * <ul>
 *   <li>Matching is case-insensitive (char-wise lower-casing keeps indices aligned).</li>
 *   <li>ASCII keywords must sit on word boundaries ({@code "ctg"} does not match
 *       {@code "facts"}).</li>
 *   <li>Bengali keywords may not start in the middle of a word, and — when
 *       {@code suffixTolerant} is on — may be followed by Bengali suffixes, so
 *       {@code খুলনা} matches {@code খুলনার} / {@code খুলনায়}.</li>
 *   <li>Longer keywords win overlapping regions, so {@code শুক্রবার} is claimed
 *       before the short form {@code শুক্র}.</li>
 * </ul>
 */
public final class KeywordMatcher {

    /** One match: {@code [start, end)} span in the original text, the lower-cased key and its payload. */
    public record Hit<T>(int start, int end, String key, T value) {
        public String literal(String originalText) {
            return originalText.substring(start, end);
        }
    }

    private KeywordMatcher() {
    }

    /** Char-wise lower case — never changes the string length, so indices stay aligned. */
    public static String lower(String value) {
        if (value == null) {
            return "";
        }
        char[] chars = value.toCharArray();
        for (int i = 0; i < chars.length; i++) {
            chars[i] = Character.toLowerCase(chars[i]);
        }
        return new String(chars);
    }

    /**
     * Finds every keyword of {@code keywords} in {@code text}, sorted by position.
     *
     * @param suffixTolerant when {@code true}, a Bengali keyword may be followed by
     *                       any character (suffix tolerance); when {@code false} it
     *                       may not be followed by another Bengali consonant
     *                       (protects short words like {@code মে} from {@code মেশিন})
     */
    public static <T> List<Hit<T>> find(String text, Map<String, T> keywords, boolean suffixTolerant) {
        if (text == null || text.isEmpty() || keywords.isEmpty()) {
            return List.of();
        }
        String lower = lower(text);
        List<Map.Entry<String, T>> ordered = new ArrayList<>(keywords.entrySet());
        ordered.sort(Comparator.comparingInt((Map.Entry<String, T> e) -> lower(e.getKey()).length()).reversed());

        boolean[] claimed = new boolean[text.length()];
        List<Hit<T>> hits = new ArrayList<>();
        for (Map.Entry<String, T> entry : ordered) {
            String key = lower(entry.getKey());
            if (key.isEmpty()) {
                continue;
            }
            int from = 0;
            while (from <= lower.length() - key.length()) {
                int index = lower.indexOf(key, from);
                if (index < 0) {
                    break;
                }
                from = index + 1;
                if (!isClaimed(claimed, index, key.length())
                        && boundariesOk(text, lower, key, index, suffixTolerant)) {
                    claim(claimed, index, key.length());
                    hits.add(new Hit<>(index, index + key.length(), key, entry.getValue()));
                }
            }
        }
        hits.sort(Comparator.comparingInt(Hit::start));
        return hits;
    }

    private static boolean boundariesOk(String text, String lower, String key, int index, boolean suffixTolerant) {
        int end = index + key.length();
        if (isAsciiKeyword(key)) {
            if (index > 0 && isWordChar(lower.charAt(index - 1))) {
                return false;
            }
            return end >= lower.length() || !isWordChar(lower.charAt(end));
        }
        if (index > 0 && isBengali(text.charAt(index - 1))) {
            return false;
        }
        if (!suffixTolerant && end < text.length() && isBengaliConsonant(text.charAt(end))) {
            return false;
        }
        return true;
    }

    private static boolean isAsciiKeyword(String key) {
        for (int i = 0; i < key.length(); i++) {
            if (key.charAt(i) > 127) {
                return false;
            }
        }
        return true;
    }

    static boolean isWordChar(char c) {
        return (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_' || c == '\'';
    }

    static boolean isBengali(char c) {
        return c >= 'ঀ' && c <= '৿';
    }

    static boolean isBengaliConsonant(char c) {
        return (c >= 'ক' && c <= 'হ') || c == 'ৰ' || c == 'ৱ';
    }

    private static boolean isClaimed(boolean[] claimed, int index, int length) {
        for (int i = index; i < index + length; i++) {
            if (claimed[i]) {
                return true;
            }
        }
        return false;
    }

    private static void claim(boolean[] claimed, int index, int length) {
        for (int i = index; i < index + length; i++) {
            claimed[i] = true;
        }
    }
}
