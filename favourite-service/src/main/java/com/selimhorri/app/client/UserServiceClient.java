package com.selimhorri.app.client;

import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestTemplate;

import com.selimhorri.app.config.properties.AppFeatureProperties;
import com.selimhorri.app.constant.AppConstant;
import com.selimhorri.app.dto.UserDto;

import io.github.resilience4j.bulkhead.annotation.Bulkhead;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Component
@RequiredArgsConstructor
@Slf4j
public class UserServiceClient {

    private static final String USER_SERVICE_CB = "favouriteUserServiceClient";

    private final RestTemplate restTemplate;
    private final AppFeatureProperties featureProperties;

    @CircuitBreaker(name = USER_SERVICE_CB, fallbackMethod = "fallbackUser")
    @Retry(name = USER_SERVICE_CB)
    @Bulkhead(name = USER_SERVICE_CB)
    public UserDto fetchUser(final Integer userId) {
        if (userId == null) {
            return buildFallbackUser(null, "missing-user-id");
        }

        if (!featureProperties.isEnrichRemoteData()) {
            return buildFallbackUser(userId, "enrichment-disabled");
        }

        final String url = AppConstant.DiscoveredDomainsApi.USER_SERVICE_API_URL + "/" + userId;
        return restTemplate.getForObject(url, UserDto.class);
    }

    @SuppressWarnings("unused")
    private UserDto fallbackUser(final Integer userId, final Throwable throwable) {
        if (featureProperties.isEnableResilienceLogs()) {
            log.warn("Falling back to cached user representation for id {} due to {}", userId,
                    throwable == null ? "unknown error" : throwable.getMessage());
        }
        return buildFallbackUser(userId, throwable == null ? "fallback" : throwable.getClass().getSimpleName());
    }

    private UserDto buildFallbackUser(final Integer userId, final String reason) {
        return UserDto.builder()
                .userId(userId)
                .firstName("User data unavailable")
                .lastName(StringUtils.hasText(reason) ? reason : "unknown")
                .build();
    }
}



