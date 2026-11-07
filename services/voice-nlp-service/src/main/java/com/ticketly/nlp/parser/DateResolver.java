package com.ticketly.nlp.parser;

import java.time.DateTimeException;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Resolves explicit and relative date expressions (Bengali + English) to a
 * {@link LocalDate}. Input is expected to have Bengali digits normalised to
 * ASCII (see {@link QueryParser#normalizeDigits}); all spans returned refer to
 * the same (1:1 mapped) string.
 *
 * <p>Precedence: explicit numeric forms first (ISO, {@code 8/11/2026},
 * {@code ৮ নভেম্বর}), then the earliest of the relative / weekday mentions
 * ({@code আজ}, {@code কাল}, {@code আগামী শুক্রবার}, {@code next friday}).</p>
 */
public final class DateResolver {

    /** A resolved date together with the {@code [start, end)} span it came from. */
    public record DateHit(LocalDate date, int start, int end) {
    }

    private static final Pattern ISO_DATE =
            Pattern.compile("(?<![0-9])\\d{4}-\\d{2}-\\d{2}(?![0-9])");
    private static final Pattern NUMERIC_DATE =
            Pattern.compile("(?<![0-9./-])(\\d{1,2})[/-](\\d{1,2})[/-](\\d{4})(?![0-9./-])");
    private static final Pattern TRAILING_DAY =
            Pattern.compile("(?<![0-9])(\\d{1,2})\\s*$");
    private static final Pattern LEADING_YEAR =
            Pattern.compile("^\\s*(\\d{4})");

    private static final Map<String, Month> BENGALI_MONTHS = bengaliMonths();
    private static final Map<String, DayOfWeek> BENGALI_DAYS = bengaliDays();
    private static final Map<String, DayOfWeek> ENGLISH_DAYS = englishDays();
    /** Keyword → days-to-add (0 = today, 1 = tomorrow). */
    private static final Map<String, Integer> RELATIVE_DAYS = relativeDays();

    private static final List<String> NEXT_PREFIXES = List.of("আগামী", "পরবর্তী", "next");

    public DateResolver() {
    }

    /** Returns the first date found in {@code text}, or {@code null}. */
    public DateHit resolve(String text, LocalDate today) {
        if (text == null || text.isEmpty()) {
            return null;
        }
        DateHit hit = firstMatch(ISO_DATE, text, g -> LocalDate.parse(g));
        if (hit != null) {
            return hit;
        }
        hit = firstMatch(NUMERIC_DATE, text, g -> {
            // Bangladesh convention: d/M/yyyy
            String[] parts = g.split("[/-]");
            return LocalDate.of(Integer.parseInt(parts[2]),
                    Integer.parseInt(parts[1]),
                    Integer.parseInt(parts[0]));
        });
        if (hit != null) {
            return hit;
        }
        hit = resolveDayAndMonth(text, today);
        if (hit != null) {
            return hit;
        }
        List<DateHit> candidates = new ArrayList<>();
        collectRelativeHits(text, today, candidates);
        collectWeekdayHits(text, today, candidates);
        return candidates.stream().min(Comparator.comparingInt(DateHit::start)).orElse(null);
    }

    private interface DateFactory {
        LocalDate create(String group) throws Exception;
    }

    private DateHit firstMatch(Pattern pattern, String text, DateFactory factory) {
        Matcher matcher = pattern.matcher(text);
        while (matcher.find()) {
            try {
                LocalDate date = factory.create(matcher.group());
                return new DateHit(date, matcher.start(), matcher.end());
            } catch (Exception ignored) {
                // syntactically present but impossible (e.g. 2026-13-45) – keep looking
            }
        }
        return null;
    }

    /** {@code ৮ নভেম্বর} / {@code 8 নভেম্বর ২০২৬} with the optional year. */
    private DateHit resolveDayAndMonth(String text, LocalDate today) {
        List<KeywordMatcher.Hit<Month>> months = KeywordMatcher.find(text, BENGALI_MONTHS, false);
        for (KeywordMatcher.Hit<Month> month : months) {
            String before = text.substring(0, month.start());
            Matcher day = TRAILING_DAY.matcher(before);
            if (!day.find()) {
                continue;
            }
            String after = text.substring(month.end());
            Matcher year = LEADING_YEAR.matcher(after);
            int yearValue = today.getYear();
            int spanEnd = month.end();
            if (year.find()) {
                yearValue = Integer.parseInt(year.group(1));
                spanEnd += year.end();
            }
            try {
                LocalDate date = LocalDate.of(yearValue, month.value().getValue(),
                        Integer.parseInt(day.group(1)));
                return new DateHit(date, day.start(), spanEnd);
            } catch (DateTimeException ignored) {
                // e.g. 31 February – try the next month mention
            }
        }
        return null;
    }

    /** আজ / কাল / tomorrow / kal and friends. */
    private void collectRelativeHits(String text, LocalDate today, List<DateHit> out) {
        for (KeywordMatcher.Hit<Integer> hit : KeywordMatcher.find(text, RELATIVE_DAYS, true)) {
            out.add(new DateHit(today.plusDays(hit.value()), hit.start(), hit.end()));
        }
    }

    /** Weekday names, with an optional "next" prefix ({@code আগামী শুক্রবার}). */
    private void collectWeekdayHits(String text, LocalDate today, List<DateHit> out) {
        Map<String, DayOfWeek> merged = new LinkedHashMap<>(BENGALI_DAYS);
        merged.putAll(ENGLISH_DAYS);
        for (KeywordMatcher.Hit<DayOfWeek> hit : KeywordMatcher.find(text, merged, true)) {
            String before = trimTrailing(text.substring(0, hit.start()));
            int prefixStart = findNextPrefix(before);
            LocalDate date = prefixStart >= 0
                    ? strictlyAfter(today, hit.value())
                    : onOrAfter(today, hit.value());
            out.add(new DateHit(date, prefixStart >= 0 ? prefixStart : hit.start(), hit.end()));
        }
    }

    /** Position of an {@code আগামী / পরবর্তী / next} prefix right before the day name, or -1. */
    private int findNextPrefix(String before) {
        for (String prefix : NEXT_PREFIXES) {
            if (before.endsWith(prefix)) {
                int start = before.length() - prefix.length();
                if (start == 0 || isBoundaryChar(before.charAt(start - 1))) {
                    return start;
                }
            }
        }
        return -1;
    }

    private static boolean isBoundaryChar(char c) {
        return !Character.isLetterOrDigit(c);
    }

    private static String trimTrailing(String value) {
        int end = value.length();
        while (end > 0 && isTrailingJunk(value.charAt(end - 1))) {
            end--;
        }
        return value.substring(0, end);
    }

    private static boolean isTrailingJunk(char c) {
        return Character.isWhitespace(c) || c == ',' || c == '.' || c == '?' || c == '!'
                || c == ';' || c == ':' || c == '।';
    }

    private static LocalDate onOrAfter(LocalDate today, DayOfWeek target) {
        LocalDate date = today;
        while (date.getDayOfWeek() != target) {
            date = date.plusDays(1);
        }
        return date;
    }

    private static LocalDate strictlyAfter(LocalDate today, DayOfWeek target) {
        LocalDate date = today.plusDays(1);
        while (date.getDayOfWeek() != target) {
            date = date.plusDays(1);
        }
        return date;
    }

    private enum Month {
        JANUARY(1), FEBRUARY(2), MARCH(3), APRIL(4), MAY(5), JUNE(6),
        JULY(7), AUGUST(8), SEPTEMBER(9), OCTOBER(10), NOVEMBER(11), DECEMBER(12);

        private final int value;

        Month(int value) {
            this.value = value;
        }

        int getValue() {
            return value;
        }
    }

    private static Map<String, Month> bengaliMonths() {
        Map<String, Month> months = new LinkedHashMap<>();
        months.put("জানুয়ারি", Month.JANUARY);
        months.put("জানুয়ার", Month.JANUARY);
        months.put("জানুয়ারী", Month.JANUARY);
        months.put("ফেব্রুয়ারি", Month.FEBRUARY);
        months.put("ফেব্রুয়ার", Month.FEBRUARY);
        months.put("ফেব্রুয়ারী", Month.FEBRUARY);
        months.put("মার্চ", Month.MARCH);
        months.put("এপ্রিল", Month.APRIL);
        months.put("মে", Month.MAY);
        months.put("জুন", Month.JUNE);
        months.put("জুলাই", Month.JULY);
        months.put("আগস্ট", Month.AUGUST);
        months.put("সেপ্টেম্বর", Month.SEPTEMBER);
        months.put("সেপটেম্বর", Month.SEPTEMBER);
        months.put("অক্টোবর", Month.OCTOBER);
        months.put("নভেম্বর", Month.NOVEMBER);
        months.put("ডিসেম্বর", Month.DECEMBER);
        return months;
    }

    private static Map<String, DayOfWeek> bengaliDays() {
        Map<String, DayOfWeek> days = new LinkedHashMap<>();
        days.put("রবিবার", DayOfWeek.SUNDAY);
        days.put("সোমবার", DayOfWeek.MONDAY);
        days.put("মঙ্গলবার", DayOfWeek.TUESDAY);
        days.put("বুধবার", DayOfWeek.WEDNESDAY);
        days.put("বৃহস্পতিবার", DayOfWeek.THURSDAY);
        days.put("শুক্রবার", DayOfWeek.FRIDAY);
        days.put("শনিবার", DayOfWeek.SATURDAY);
        // short forms
        days.put("রবি", DayOfWeek.SUNDAY);
        days.put("সোম", DayOfWeek.MONDAY);
        days.put("মঙ্গল", DayOfWeek.TUESDAY);
        days.put("বুধ", DayOfWeek.WEDNESDAY);
        days.put("বৃহস্পতি", DayOfWeek.THURSDAY);
        days.put("শুক্র", DayOfWeek.FRIDAY);
        days.put("শনি", DayOfWeek.SATURDAY);
        return days;
    }

    private static Map<String, DayOfWeek> englishDays() {
        Map<String, DayOfWeek> days = new LinkedHashMap<>();
        days.put("sunday", DayOfWeek.SUNDAY);
        days.put("monday", DayOfWeek.MONDAY);
        days.put("tuesday", DayOfWeek.TUESDAY);
        days.put("wednesday", DayOfWeek.WEDNESDAY);
        days.put("thursday", DayOfWeek.THURSDAY);
        days.put("friday", DayOfWeek.FRIDAY);
        days.put("saturday", DayOfWeek.SATURDAY);
        days.put("sun", DayOfWeek.SUNDAY);
        days.put("mon", DayOfWeek.MONDAY);
        days.put("tue", DayOfWeek.TUESDAY);
        days.put("wed", DayOfWeek.WEDNESDAY);
        days.put("thu", DayOfWeek.THURSDAY);
        days.put("fri", DayOfWeek.FRIDAY);
        days.put("sat", DayOfWeek.SATURDAY);
        return days;
    }

    private static Map<String, Integer> relativeDays() {
        Map<String, Integer> relative = new LinkedHashMap<>();
        relative.put("আগামীকাল", 1);
        relative.put("আগামী কাল", 1);
        relative.put("আজ", 0);
        relative.put("কাল", 1);
        relative.put("today", 0);
        relative.put("tomorrow", 1);
        relative.put("kal", 1);
        return relative;
    }
}
