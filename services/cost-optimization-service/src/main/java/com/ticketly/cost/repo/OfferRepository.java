package com.ticketly.cost.repo;

import com.ticketly.cost.domain.Offer;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OfferRepository extends JpaRepository<Offer, Long> {
}
