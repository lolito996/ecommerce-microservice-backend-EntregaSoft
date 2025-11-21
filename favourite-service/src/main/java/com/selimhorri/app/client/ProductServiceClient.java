package com.selimhorri.app.client;

import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestTemplate;

import com.selimhorri.app.config.properties.AppFeatureProperties;
import com.selimhorri.app.constant.AppConstant;
import com.selimhorri.app.dto.ProductDto;

import io.github.resilience4j.bulkhead.annotation.Bulkhead;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Component
@RequiredArgsConstructor
@Slf4j
public class ProductServiceClient {

    private static final String PRODUCT_SERVICE_CB = "favouriteProductServiceClient";

    private final RestTemplate restTemplate;
    private final AppFeatureProperties featureProperties;

    @CircuitBreaker(name = PRODUCT_SERVICE_CB, fallbackMethod = "fallbackProduct")
    @Retry(name = PRODUCT_SERVICE_CB)
    @Bulkhead(name = PRODUCT_SERVICE_CB)
    public ProductDto fetchProduct(final Integer productId) {
        if (productId == null) {
            return buildFallbackProduct(null, "missing-product-id");
        }

        if (!featureProperties.isEnrichRemoteData()) {
            return buildFallbackProduct(productId, "enrichment-disabled");
        }

        final String url = AppConstant.DiscoveredDomainsApi.PRODUCT_SERVICE_API_URL + "/" + productId;
        return restTemplate.getForObject(url, ProductDto.class);
    }

    @SuppressWarnings("unused")
    private ProductDto fallbackProduct(final Integer productId, final Throwable throwable) {
        if (featureProperties.isEnableResilienceLogs()) {
            log.warn("Falling back to cached product representation for id {} due to {}", productId,
                    throwable == null ? "unknown error" : throwable.getMessage());
        }
        return buildFallbackProduct(productId, throwable == null ? "fallback" : throwable.getClass().getSimpleName());
    }

    private ProductDto buildFallbackProduct(final Integer productId, final String reason) {
        return ProductDto.builder()
                .productId(productId)
                .productTitle("Product data unavailable - " + (StringUtils.hasText(reason) ? reason : "unknown"))
                .build();
    }
}



