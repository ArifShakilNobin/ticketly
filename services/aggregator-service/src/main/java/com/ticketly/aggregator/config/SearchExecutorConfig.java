package com.ticketly.aggregator.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;

/** Bounded pool used to fan out to the transport providers in parallel. */
@Configuration
public class SearchExecutorConfig {

    @Bean(destroyMethod = "shutdownNow")
    public ExecutorService searchExecutor(@Value("${aggregator.search-threads:8}") int threads) {
        AtomicInteger counter = new AtomicInteger();
        return Executors.newFixedThreadPool(Math.max(2, threads), runnable -> {
            Thread thread = new Thread(runnable, "provider-search-" + counter.incrementAndGet());
            thread.setDaemon(true);
            return thread;
        });
    }
}
