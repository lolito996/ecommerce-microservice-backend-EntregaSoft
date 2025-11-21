package com.selimhorri.app.config.properties;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import lombok.Data;

@Data
@Configuration
@ConfigurationProperties(prefix = "app.features")
public class AppFeatureProperties {

    private boolean enrichRemoteData = true;
    private boolean enableResilienceLogs = true;
}



