package com.selimhorri.app.client;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.client.RestTemplate;

import com.selimhorri.app.config.properties.AppFeatureProperties;
import com.selimhorri.app.dto.ProductDto;

@ExtendWith(MockitoExtension.class)
@DisplayName("ProductServiceClient Tests")
class ProductServiceClientTest {

    @Mock
    private RestTemplate restTemplate;

    @Mock
    private AppFeatureProperties featureProperties;

    @InjectMocks
    private ProductServiceClient productServiceClient;

    private ProductDto productDto;
    private Integer productId;

    @BeforeEach
    void setUp() {
        productId = 1;
        productDto = ProductDto.builder()
                .productId(productId)
                .productTitle("Test Product")
                .productPrice(99.99)
                .build();
    }

    @Test
    @DisplayName("Should fetch product successfully when enrichment is enabled")
    void testFetchProduct_WithEnrichmentEnabled_ShouldReturnProduct() {
        // Given
        when(featureProperties.isEnrichRemoteData()).thenReturn(true);
        when(restTemplate.getForObject(anyString(), eq(ProductDto.class))).thenReturn(productDto);

        // When
        ProductDto result = productServiceClient.fetchProduct(productId);

        // Then
        assertNotNull(result);
        assertEquals(productId, result.getProductId());
        verify(featureProperties).isEnrichRemoteData();
        verify(restTemplate).getForObject(anyString(), eq(ProductDto.class));
    }

    @Test
    @DisplayName("Should return fallback product when enrichment is disabled")
    void testFetchProduct_WithEnrichmentDisabled_ShouldReturnFallback() {
        // Given
        when(featureProperties.isEnrichRemoteData()).thenReturn(false);

        // When
        ProductDto result = productServiceClient.fetchProduct(productId);

        // Then
        assertNotNull(result);
        assertEquals(productId, result.getProductId());
        assertTrue(result.getProductTitle().contains("enrichment-disabled"));
        verify(featureProperties).isEnrichRemoteData();
        verify(restTemplate, never()).getForObject(anyString(), any());
    }

    @Test
    @DisplayName("Should return fallback product when productId is null")
    void testFetchProduct_WithNullProductId_ShouldReturnFallback() {
        // When
        ProductDto result = productServiceClient.fetchProduct(null);

        // Then
        assertNotNull(result);
        assertNull(result.getProductId());
        assertTrue(result.getProductTitle().contains("missing-product-id"));
        verify(restTemplate, never()).getForObject(anyString(), any());
    }
}

