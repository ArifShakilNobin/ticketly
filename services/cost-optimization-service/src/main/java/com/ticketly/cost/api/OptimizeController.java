package com.ticketly.cost.api;

import com.ticketly.common.dto.cost.OptimizeRequest;
import com.ticketly.common.dto.cost.OptimizeResponse;
import com.ticketly.cost.service.OptimizeService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Internal pricing endpoint.
 *
 * <p><b>It is intentionally public (no JWT).</b> The aggregator service and the booking service call
 * it server-to-server with plain HTTP requests and no user token; in Docker it is
 * only reachable on the internal network, is not routed through the API gateway for anonymous use,
 * and must answer even when the caller has no principal. Everything it returns is derived from fares
 * the caller already sent plus the (public) offer catalogue, so exposing it carries no user data.</p>
 */
@RestController
@RequestMapping("/api/v1/optimize")
public class OptimizeController {

    private final OptimizeService optimizeService;

    public OptimizeController(OptimizeService optimizeService) {
        this.optimizeService = optimizeService;
    }

    /** Prices, badges and ranks the given fares. Missing/empty {@code items} → empty result. */
    @PostMapping
    public OptimizeResponse optimize(@RequestBody(required = false) OptimizeRequest request) {
        return optimizeService.optimize(request);
    }
}
