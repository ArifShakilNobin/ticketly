package com.ticketly.cost.api;

import com.ticketly.common.dto.cost.OfferResponse;
import com.ticketly.cost.service.OptimizeService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** Public catalogue of the offers that are currently active. */
@RestController
@RequestMapping("/api/v1/offers")
public class OfferController {

    private final OptimizeService optimizeService;

    public OfferController(OptimizeService optimizeService) {
        this.optimizeService = optimizeService;
    }

    @GetMapping
    public List<OfferResponse> offers() {
        return optimizeService.activeOffers();
    }
}
