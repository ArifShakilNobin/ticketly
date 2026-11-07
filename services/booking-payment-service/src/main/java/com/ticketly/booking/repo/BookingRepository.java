package com.ticketly.booking.repo;

import com.ticketly.booking.domain.Booking;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface BookingRepository extends JpaRepository<Booking, String> {

    List<Booking> findByUserIdOrderByCreatedAtDesc(String userId);

    Optional<Booking> findByIdAndUserId(String id, String userId);

    boolean existsByPnr(String pnr);
}
