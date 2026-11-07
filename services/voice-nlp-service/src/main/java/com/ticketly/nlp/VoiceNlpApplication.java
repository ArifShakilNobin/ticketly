package com.ticketly.nlp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/** Turns Bengali / Banglish voice or text queries into structured search queries. */
@SpringBootApplication(scanBasePackages = "com.ticketly")
public class VoiceNlpApplication {

    public static void main(String[] args) {
        SpringApplication.run(VoiceNlpApplication.class, args);
    }
}
