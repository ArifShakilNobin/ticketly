package com.ticketly.nlp.parser;

import com.ticketly.common.dto.SearchPriority;
import com.ticketly.common.dto.TicketIntent;
import com.ticketly.common.dto.TransportType;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Rule-based, offline parser that turns a Bengali / Banglish query into a
 * structured {@link ParsedQuery}. Every rule is backed by a plain static data
 * structure (keyword maps, phrase lists, regexes) so it is unit-testable
 * without a Spring context or network.
 *
 * <p>Handles both Bengali script and Latin transliteration (Banglish), Bengali
 * postpositions ({@code ঢাকা থেকে খুলনা}, {@code খুলনায়}), Bengali digits and
 * relative dates.</p>
 */
@Component
public class QueryParser {

    // ------------------------------------------------------------------ data

    /** transport keyword (lower-case) → mode. Order irrelevant: the matcher sorts by length. */
    static final Map<String, TransportType> TRANSPORT_KEYWORDS = new LinkedHashMap<>();

    static {
        TRANSPORT_KEYWORDS.put("ট্রেন", TransportType.TRAIN);
        TRANSPORT_KEYWORDS.put("রেল", TransportType.TRAIN);
        TRANSPORT_KEYWORDS.put("train", TransportType.TRAIN);
        TRANSPORT_KEYWORDS.put("railway", TransportType.TRAIN);
        TRANSPORT_KEYWORDS.put("rail", TransportType.TRAIN);
        TRANSPORT_KEYWORDS.put("বাস", TransportType.BUS);
        TRANSPORT_KEYWORDS.put("bus", TransportType.BUS);
        TRANSPORT_KEYWORDS.put("লঞ্চ", TransportType.LAUNCH);
        TRANSPORT_KEYWORDS.put("জাহাজ", TransportType.LAUNCH);
        TRANSPORT_KEYWORDS.put("launch", TransportType.LAUNCH);
        TRANSPORT_KEYWORDS.put("ferry", TransportType.LAUNCH);
        TRANSPORT_KEYWORDS.put("ফ্লাইট", TransportType.FLIGHT);
        TRANSPORT_KEYWORDS.put("প্লেন", TransportType.FLIGHT);
        TRANSPORT_KEYWORDS.put("বিমান", TransportType.FLIGHT);
        TRANSPORT_KEYWORDS.put("flight", TransportType.FLIGHT);
        TRANSPORT_KEYWORDS.put("plane", TransportType.FLIGHT);
    }

    /** priority keyword → ranking preference. */
    static final Map<String, SearchPriority> PRIORITY_KEYWORDS = new LinkedHashMap<>();

    static {
        PRIORITY_KEYWORDS.put("সস্তা", SearchPriority.CHEAPEST);
        PRIORITY_KEYWORDS.put("সবচেয়ে কম", SearchPriority.CHEAPEST);
        PRIORITY_KEYWORDS.put("সবার কম", SearchPriority.CHEAPEST);
        PRIORITY_KEYWORDS.put("কম ভাড়া", SearchPriority.CHEAPEST);
        PRIORITY_KEYWORDS.put("কম দাম", SearchPriority.CHEAPEST);
        PRIORITY_KEYWORDS.put("সাশ্রয়", SearchPriority.CHEAPEST);
        PRIORITY_KEYWORDS.put("cheapest", SearchPriority.CHEAPEST);
        PRIORITY_KEYWORDS.put("low fare", SearchPriority.CHEAPEST);
        PRIORITY_KEYWORDS.put("low price", SearchPriority.CHEAPEST);
        PRIORITY_KEYWORDS.put("affordable", SearchPriority.CHEAPEST);
        PRIORITY_KEYWORDS.put("দ্রুত", SearchPriority.FASTEST);
        PRIORITY_KEYWORDS.put("দ্রুততম", SearchPriority.FASTEST);
        PRIORITY_KEYWORDS.put("কম সময়", SearchPriority.FASTEST);
        PRIORITY_KEYWORDS.put("এক্সপ্রেস", SearchPriority.FASTEST);
        PRIORITY_KEYWORDS.put("fastest", SearchPriority.FASTEST);
        PRIORITY_KEYWORDS.put("express", SearchPriority.FASTEST);
        PRIORITY_KEYWORDS.put("quickly", SearchPriority.FASTEST);
    }

    static final List<String> BOOK_PHRASES = List.of(
            "বুক কর", "টিকিট কিনি", "টিকিট কিনতে", "টিকিট কেনা", "টিকিট কিনব",
            "কিনে দাও", "কিনে দিন", "কিনতে চাই", "কিনে দেওয়া");
    static final Set<String> BOOK_TOKENS = Set.of("buy", "buys", "purchase", "reserve");

    static final List<String> STATUS_PHRASES = List.of(
            "স্ট্যাটাস", "যাচাই", "অবস্থা", "পিএনআর", "ট্র্যাক");
    static final Set<String> STATUS_TOKENS = Set.of("pnr", "status", "track", "tracking");

    /** "When does the train leave" style phrases — status unless a route is known. */
    static final List<String> DEPARTURE_PHRASES = List.of(
            "কখন ছাড়বে", "কখন ছাড়ছে", "কখন যাবে", "কখন পৌঁছাবে",
            "ছাড়ার সময়", "সময়সূচি", "when does", "departure time", "departure");
    static final Set<String> DEPARTURE_TOKENS = Set.of("schedule", "timetable");

    static final List<String> FROM_WORDS = List.of("থেকে", "theke", "from");

    private static final Pattern TOKENS = Pattern.compile("[^a-z0-9']+");

    private static final Pattern AMOUNT_THEN_CURRENCY = Pattern.compile(
            "([0-9]{1,7}(?:\\.[0-9]+)?)\\s*(?:টাকা|taka|tk|bdt|৳)",
            Pattern.CASE_INSENSITIVE);
    private static final Pattern CURRENCY_THEN_AMOUNT = Pattern.compile(
            "(?:৳|bdt|tk\\.?)\\s*([0-9]{1,7}(?:\\.[0-9]+)?)",
            Pattern.CASE_INSENSITIVE);
    private static final Pattern BUDGET_WORD = Pattern.compile(
            "(?:budget|বাজেট)[^0-9]{0,12}([0-9]{1,7})",
            Pattern.CASE_INSENSITIVE);
    private static final Pattern BARE_AMOUNT = Pattern.compile(
            "(?<![0-9./:-])([0-9]{2,7})(?![0-9.:-])");

    // --------------------------------------------------------------- helpers

    private final CityDictionary cityDictionary = new CityDictionary();
    private final DateResolver dateResolver = new DateResolver();

    public CityDictionary cityDictionary() {
        return cityDictionary;
    }

    public DateResolver dateResolver() {
        return dateResolver;
    }

    /** Bengali digits ০-৯ → ASCII 0-9, one char for one char (spans stay aligned). */
    public static String normalizeDigits(String value) {
        if (value == null) {
            return null;
        }
        char[] chars = value.toCharArray();
        for (int i = 0; i < chars.length; i++) {
            if (chars[i] >= '০' && chars[i] <= '৯') {
                chars[i] = (char) ('0' + (chars[i] - '০'));
            }
        }
        return new String(chars);
    }

    // ----------------------------------------------------------------- parse

    public ParsedQuery parse(String text) {
        return parse(text, LocalDate.now());
    }

    public ParsedQuery parse(String rawText, LocalDate today) {
        if (rawText == null || rawText.isBlank()) {
            return new ParsedQuery(TicketIntent.UNKNOWN, null, null, TransportType.ALL,
                    null, null, SearchPriority.BALANCED, 0.0, List.of());
        }
        String text = rawText.trim();
        String lower = KeywordMatcher.lower(text);
        String normalized = normalizeDigits(text);
        LinkedHashSet<String> terms = new LinkedHashSet<>();

        // 1. route (city NER + থেকে / theke / from heuristics)
        List<KeywordMatcher.Hit<String>> cityHits = cityDictionary.find(text);
        String source = null;
        String destination = null;
        for (KeywordMatcher.Hit<String> hit : cityHits) {
            terms.add(hit.value());
        }
        if (cityHits.size() >= 2) {
            source = cityHits.get(0).value();
            destination = cityHits.get(1).value();
        } else if (cityHits.size() == 1) {
            KeywordMatcher.Hit<String> only = cityHits.get(0);
            if (isFollowedByFrom(text, only) || isPrecededByFrom(lower, only)) {
                source = only.value();
            } else {
                destination = only.value();
            }
        }

        // 2. transport mode
        TransportType transport = TransportType.ALL;
        for (KeywordMatcher.Hit<TransportType> hit
                : KeywordMatcher.find(text, TRANSPORT_KEYWORDS, true)) {
            if (isBengaliNounFalsePositive(text, hit)) {
                continue;
            }
            transport = hit.value();
            terms.add(hit.literal(text));
            break;
        }

        // 3. travel date (explicit numeric first, then relative/weekday)
        DateResolver.DateHit dateHit = dateResolver.resolve(normalized, today);
        LocalDate travelDate = null;
        String budgetScan = normalized;
        if (dateHit != null) {
            travelDate = dateHit.date();
            terms.add(text.substring(dateHit.start(), dateHit.end()));
            budgetScan = blankOut(normalized, dateHit.start(), dateHit.end());
        }

        // 4. budget limit
        BudgetHit budget = extractBudget(budgetScan, text);
        if (budget != null) {
            terms.add(budget.literal());
        }

        // 5. ranking priority
        SearchPriority priority = SearchPriority.BALANCED;
        List<KeywordMatcher.Hit<SearchPriority>> priorityHits =
                KeywordMatcher.find(text, PRIORITY_KEYWORDS, true);
        if (!priorityHits.isEmpty()) {
            KeywordMatcher.Hit<SearchPriority> hit = priorityHits.get(0);
            priority = hit.value();
            terms.add(hit.literal(text));
        }

        // 6. intent (book > status > departure > search > unknown)
        String intentTerm = firstMatchedPhrase(lower);
        if (intentTerm != null) {
            terms.add(intentTerm);
        }
        TicketIntent intent = resolveIntent(lower, source != null || destination != null,
                travelDate, transport);

        double confidence = confidence(source, destination, transport, travelDate, intent,
                budget, priority);

        return new ParsedQuery(intent, source, destination, transport, travelDate,
                budget == null ? null : budget.value(), priority, confidence,
                List.copyOf(terms));
    }

    // ----------------------------------------------------------------- route

    private boolean isFollowedByFrom(String originalText, KeywordMatcher.Hit<?> hit) {
        String rest = KeywordMatcher.lower(originalText.substring(hit.end())).stripLeading();
        if (rest.startsWith("থেকে")) {
            return true;
        }
        return startsWithWord(rest, "theke") || startsWithWord(rest, "from");
    }

    private boolean isPrecededByFrom(String lowerText, KeywordMatcher.Hit<?> hit) {
        String before = lowerText.substring(0, hit.start()).stripTrailing();
        for (String word : FROM_WORDS) {
            if (before.endsWith(word)) {
                int start = before.length() - word.length();
                if (start == 0) {
                    return true;
                }
                char boundary = before.charAt(start - 1);
                if (!KeywordMatcher.isWordChar(boundary) && !KeywordMatcher.isBengali(boundary)) {
                    return true;
                }
            }
        }
        return false;
    }

    private static boolean startsWithWord(String value, String word) {
        if (!value.startsWith(word)) {
            return false;
        }
        return value.length() == word.length() || !KeywordMatcher.isWordChar(value.charAt(word.length()));
    }

    /**
     * Guards {@code বাস} (bus) against {@code বাসা} / {@code বাসায়} (house),
     * where the vowel sign া follows the keyword.
     */
    private boolean isBengaliNounFalsePositive(String text, KeywordMatcher.Hit<?> hit) {
        return "বাস".equals(hit.key())
                && hit.end() < text.length()
                && text.charAt(hit.end()) == 'া';
    }

    // ---------------------------------------------------------------- budget

    private record BudgetHit(BigDecimal value, int start, int end, String literal) {
    }

    private BudgetHit extractBudget(String normalized, String original) {
        for (Pattern pattern : List.of(AMOUNT_THEN_CURRENCY, CURRENCY_THEN_AMOUNT,
                BUDGET_WORD, BARE_AMOUNT)) {
            Matcher matcher = pattern.matcher(normalized);
            if (matcher.find()) {
                // every pattern keeps the amount in group 1
                String amount = matcher.group(1);
                return new BudgetHit(new BigDecimal(amount),
                        matcher.start(1), matcher.end(1),
                        original.substring(matcher.start(1), matcher.end(1)));
            }
        }
        return null;
    }

    private static String blankOut(String value, int start, int end) {
        char[] chars = value.toCharArray();
        for (int i = Math.max(0, start); i < Math.min(end, chars.length); i++) {
            chars[i] = ' ';
        }
        return new String(chars);
    }

    // ---------------------------------------------------------------- intent

    private String firstMatchedPhrase(String lower) {
        List<String> tokens = tokens(lower);
        for (String phrase : BOOK_PHRASES) {
            if (lower.contains(phrase)) {
                return phrase;
            }
        }
        for (String token : tokens) {
            if (token.startsWith("book") || BOOK_TOKENS.contains(token)) {
                return token;
            }
        }
        for (String phrase : STATUS_PHRASES) {
            if (lower.contains(phrase)) {
                return phrase;
            }
        }
        for (String token : tokens) {
            if (STATUS_TOKENS.contains(token)) {
                return token;
            }
        }
        for (String phrase : DEPARTURE_PHRASES) {
            if (lower.contains(phrase)) {
                return phrase;
            }
        }
        for (String token : tokens) {
            if (DEPARTURE_TOKENS.contains(token)) {
                return token;
            }
        }
        return null;
    }

    private TicketIntent resolveIntent(String lower, boolean routeKnown,
                                       LocalDate travelDate, TransportType transport) {
        boolean book = containsAnyPhrase(lower, BOOK_PHRASES) || containsAnyToken(lower, t ->
                t.startsWith("book") || BOOK_TOKENS.contains(t));
        if (book) {
            return TicketIntent.BOOK_TICKET;
        }
        boolean status = containsAnyPhrase(lower, STATUS_PHRASES)
                || containsAnyToken(lower, STATUS_TOKENS::contains);
        if (status) {
            return TicketIntent.CHECK_STATUS;
        }
        boolean departure = containsAnyPhrase(lower, DEPARTURE_PHRASES)
                || containsAnyToken(lower, DEPARTURE_TOKENS::contains);
        if (departure) {
            // "ঢাকা থেকে খুলনার ট্রেন কখন ছাড়বে" reads as a search; a bare
            // "ট্রেন কখন ছাড়বে" (no route) reads as a schedule/status lookup.
            return routeKnown ? TicketIntent.SEARCH_TICKET : TicketIntent.CHECK_STATUS;
        }
        boolean searchSignal = routeKnown || travelDate != null || transport != TransportType.ALL;
        return searchSignal ? TicketIntent.SEARCH_TICKET : TicketIntent.UNKNOWN;
    }

    private static boolean containsAnyPhrase(String lower, List<String> phrases) {
        for (String phrase : phrases) {
            if (lower.contains(phrase)) {
                return true;
            }
        }
        return false;
    }

    @FunctionalInterface
    private interface TokenPredicate {
        boolean test(String token);
    }

    private static boolean containsAnyToken(String lower, TokenPredicate predicate) {
        for (String token : TOKENS.split(lower)) {
            if (!token.isEmpty() && predicate.test(token)) {
                return true;
            }
        }
        return false;
    }

    private static List<String> tokens(String lower) {
        List<String> tokens = new ArrayList<>();
        for (String token : TOKENS.split(lower)) {
            if (!token.isEmpty()) {
                tokens.add(token);
            }
        }
        return tokens;
    }

    // ------------------------------------------------------------ confidence

    private static double confidence(String source, String destination, TransportType transport,
                                     LocalDate travelDate, TicketIntent intent,
                                     BudgetHit budget, SearchPriority priority) {
        double score = 0.0;
        if (source != null && destination != null) {
            score += 0.4;
        } else if (source != null || destination != null) {
            score += 0.2;
        }
        if (transport != TransportType.ALL) {
            score += 0.2;
        }
        if (travelDate != null) {
            score += 0.2;
        }
        if (intent != TicketIntent.UNKNOWN) {
            score += 0.1;
        }
        if (budget != null) {
            score += 0.05;
        }
        if (priority != SearchPriority.BALANCED) {
            score += 0.05;
        }
        return Math.min(1.0, Math.round(score * 100.0) / 100.0);
    }
}
