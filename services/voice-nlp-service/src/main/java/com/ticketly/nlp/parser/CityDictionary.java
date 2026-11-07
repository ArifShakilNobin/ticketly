package com.ticketly.nlp.parser;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Dictionary of Bangladeshi cities: alias (lower-cased) → canonical display name.
 * Bengali aliases map to the Bengali name, Latin (Banglish) aliases to the English
 * name, so the response always echoes the script the user spoke.
 *
 * <p>Bengali suffixes are handled by the matcher's suffix tolerance
 * ({@code ঢাকা থেকে খুলনার টিকিট} → destination {@code খুলনা}).</p>
 */
public final class CityDictionary {

    private final Map<String, String> aliases = new LinkedHashMap<>();

    public CityDictionary() {
        // Dhaka division
        add("ঢাকা", "ঢাকা");
        add("dhaka", "Dhaka");
        add("চট্টগ্রাম", "চট্টগ্রাম");
        add("চট্টম", "চট্টগ্রাম");
        add("chattogram", "Chattogram");
        add("chittagong", "Chittagong");
        add("ctg", "CTG");
        add("নারায়ণগঞ্জ", "নারায়ণগঞ্জ");
        add("narayanganj", "Narayanganj");
        add("গাজীপুর", "গাজীপুর");
        add("gazipur", "Gazipur");
        add("মুন্সিগঞ্জ", "মুন্সিগঞ্জ");
        add("munshiganj", "Munshiganj");
        add("ফেনী", "ফেনী");
        add("feni", "Feni");
        add("চাঁদপুর", "চাঁদপুর");
        add("chandpur", "Chandpur");
        add("নোয়াখালী", "নোয়াখালী");
        add("noakhali", "Noakhali");

        // Other divisions
        add("খুলনা", "খুলনা");
        add("khulna", "Khulna");
        add("যশোর", "যশোর");
        add("jashore", "Jashore");
        add("jessore", "Jessore");
        add("মেহেরপুর", "মেহেরপুর");
        add("meherpur", "Meherpur");
        add("সিলেট", "সিলেট");
        add("sylhet", "Sylhet");
        add("রাজশাহী", "রাজশাহী");
        add("rajshahi", "Rajshahi");
        add("বগুড়া", "বগুড়া");
        add("bogura", "Bogura");
        add("bogra", "Bogra");
        add("দিনাজপুর", "দিনাজপুর");
        add("dinajpur", "Dinajpur");
        add("ঠাকুরগাঁও", "ঠাকুরগাঁও");
        add("thakurgaon", "Thakurgaon");
        add("রংপুর", "রংপুর");
        add("rangpur", "Rangpur");
        add("লালমনিরহাট", "লালমনিরহাট");
        add("lalmonirhat", "Lalmonirhat");
        add("বরিশাল", "বরিশাল");
        add("barishal", "Barishal");
        add("barisal", "Barisal");
        add("পাবনা", "পাবনা");
        add("pabna", "Pabna");
        add("কুমিল্লা", "কুমিল্লা");
        add("cumilla", "Cumilla");
        add("comilla", "Comilla");
        add("টাঙ্গাইল", "টাঙ্গাইল");
        add("tangail", "Tangail");
        add("ময়মনসিংহ", "ময়মনসিংহ");
        add("mymensingh", "Mymensingh");
        add("কক্সবাজার", "কক্সবাজার");
        add("coxsbazar", "Coxsbazar");
        add("cox's bazar", "Cox's Bazar");
        add("cox bazar", "Cox Bazar");
    }

    private void add(String alias, String canonical) {
        aliases.put(KeywordMatcher.lower(alias), canonical);
    }

    /** Alias → canonical name map (plain data, exposed for tests). */
    public Map<String, String> aliases() {
        return Collections.unmodifiableMap(aliases);
    }

    /** All city matches in the text, sorted by position. */
    public List<KeywordMatcher.Hit<String>> find(String text) {
        return KeywordMatcher.find(text, aliases, true);
    }
}
