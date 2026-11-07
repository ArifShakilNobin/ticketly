package com.ticketly.booking.config;

import com.ticketly.common.event.Topics;
import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;

/** Kafka topics consumed/emitted across the platform and produced by this service. */
@Configuration
public class KafkaConfig {

    @Bean
    public NewTopic bookingConfirmedTopic() {
        return TopicBuilder.name(Topics.BOOKING_CONFIRMED).partitions(1).replicas(1).build();
    }

    @Bean
    public NewTopic bookingCancelledTopic() {
        return TopicBuilder.name(Topics.BOOKING_CANCELLED).partitions(1).replicas(1).build();
    }
}
