package com.ticketly.notification;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/** Consumes booking events and delivers (mock) SMS/e-mail notifications. */
@SpringBootApplication(scanBasePackages = "com.ticketly")
public class NotificationApplication {

    public static void main(String[] args) {
        SpringApplication.run(NotificationApplication.class, args);
    }
}
