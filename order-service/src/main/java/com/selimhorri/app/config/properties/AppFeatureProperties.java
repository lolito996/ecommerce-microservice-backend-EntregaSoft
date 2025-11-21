package com.selimhorri.app.config.properties;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import lombok.Data;

/**
 * Feature-toggle style configuration that lets us enable/disable
 * cross-service enrichment without code changes. This implements
 * the External Configuration pattern in a centralized way so we
 * can control behaviour per environment from config server.
 */
@Data
@Configuration
@ConfigurationProperties(prefix = "app.features")
public class AppFeatureProperties {

    /**
     * When false, services will stop performing remote enrichment calls
     * and rely on local data only.
     */
    private boolean enrichRemoteData = true;

    /**
     * Enable verbose logging whenever we use a fallback or resilience
     * strategy so operators can observe degraded modes.
     */
    private boolean enableResilienceLogs = true;
}



