package com.ticketly.aggregator.repo;

import com.ticketly.aggregator.domain.SearchLog;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface SearchLogRepository extends MongoRepository<SearchLog, String> {
}
