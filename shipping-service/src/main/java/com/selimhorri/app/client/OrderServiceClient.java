package com.selimhorri.app.client;

import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestTemplate;

import com.selimhorri.app.config.properties.AppFeatureProperties;
import com.selimhorri.app.constant.AppConstant;
import com.selimhorri.app.dto.OrderDto;

import io.github.resilience4j.bulkhead.annotation.Bulkhead;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Component
@RequiredArgsConstructor
@Slf4j
public class OrderServiceClient {

    private static final String ORDER_SERVICE_CB = "shippingOrderServiceClient";

    private final RestTemplate restTemplate;
    private final AppFeatureProperties featureProperties;

    @CircuitBreaker(name = ORDER_SERVICE_CB, fallbackMethod = "fallbackOrder")
    @Retry(name = ORDER_SERVICE_CB)
    @Bulkhead(name = ORDER_SERVICE_CB)
    public OrderDto fetchOrder(final Integer orderId) {
        if (orderId == null) {
            return buildFallbackOrder(null, "missing-order-id");
        }

        if (!featureProperties.isEnrichRemoteData()) {
            return buildFallbackOrder(orderId, "enrichment-disabled");
        }

        final String url = AppConstant.DiscoveredDomainsApi.ORDER_SERVICE_API_URL + "/" + orderId;
        return restTemplate.getForObject(url, OrderDto.class);
    }

    @SuppressWarnings("unused")
    private OrderDto fallbackOrder(final Integer orderId, final Throwable throwable) {
        if (featureProperties.isEnableResilienceLogs()) {
            log.warn("Falling back to cached order representation for id {} due to {}", orderId,
                    throwable == null ? "unknown error" : throwable.getMessage());
        }
        return buildFallbackOrder(orderId, throwable == null ? "fallback" : throwable.getClass().getSimpleName());
    }

    private OrderDto buildFallbackOrder(final Integer orderId, final String reason) {
        return OrderDto.builder()
                .orderId(orderId)
                .orderDesc("Order unavailable - " + (StringUtils.hasText(reason) ? reason : "unknown"))
                .build();
    }
}



