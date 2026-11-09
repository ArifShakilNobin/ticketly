package com.ticketly.aggregator.api;

import com.ticketly.aggregator.service.SearchService;
import com.ticketly.common.dto.search.SearchRequest;
import com.ticketly.common.dto.search.SearchResponse;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Anonymous multi-modal search: aggregates every configured transport provider,
 * prices the result through the cost engine and returns it ranked.
 */
@RestController
@RequestMapping("/api/v1/search")
public class SearchController {

    private final SearchService searchService;

    public SearchController(SearchService searchService) {
        this.searchService = searchService;
    }

    @PostMapping
    public SearchResponse search(@RequestBody(required = false) SearchRequest request) {
        return searchService.search(request);
    }
}
