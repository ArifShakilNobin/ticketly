package com.ticketly.booking.events;

import com.ticketly.common.event.BookingCancelledEvent;
import com.ticketly.common.event.BookingConfirmedEvent;
import com.ticketly.common.event.Topics;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

/**
 * Publishes booking events. Every send is wrapped so a Kafka outage can never fail a booking —
 * failures are logged at ERROR and the booking stays as it is.
 */
@Component
public class BookingEventPublisher {

    private static final Logger log = LoggerFactory.getLogger(BookingEventPublisher.class);

    private final KafkaTemplate<String, Object> kafkaTemplate;

    public BookingEventPublisher(KafkaTemplate<String, Object> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    public void bookingConfirmed(BookingConfirmedEvent event) {
        send(Topics.BOOKING_CONFIRMED, event.bookingId(), event);
    }

    public void bookingCancelled(BookingCancelledEvent event) {
        send(Topics.BOOKING_CANCELLED, event.bookingId(), event);
    }

    private void send(String topic, String key, Object payload) {
        try {
            kafkaTemplate.send(topic, key, payload).whenComplete((result, ex) -> {
                if (ex != null) {
                    log.error("Failed to publish event to topic '{}' for key '{}'", topic, key, ex);
                } else {
                    log.info("Published event to topic '{}' partition {} offset {}",
                            topic,
                            result.getRecordMetadata() == null ? "?" : result.getRecordMetadata().partition(),
                            result.getRecordMetadata() == null ? "?" : result.getRecordMetadata().offset());
                }
            });
        } catch (Exception ex) {
            log.error("Failed to publish event to topic '{}' for key '{}'", topic, key, ex);
        }
    }
}
