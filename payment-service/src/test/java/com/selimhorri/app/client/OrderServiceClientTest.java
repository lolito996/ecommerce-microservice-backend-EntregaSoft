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
import com.selimhorri.app.dto.OrderDto;

@ExtendWith(MockitoExtension.class)
@DisplayName("OrderServiceClient Tests")
class OrderServiceClientTest {

    @Mock
    private RestTemplate restTemplate;

    @Mock
    private AppFeatureProperties featureProperties;

    @InjectMocks
    private OrderServiceClient orderServiceClient;

    private OrderDto orderDto;
    private Integer orderId;

    @BeforeEach
    void setUp() {
        orderId = 1;
        orderDto = OrderDto.builder()
                .orderId(orderId)
                .orderDesc("Test Order")
                .orderFee(100.0)
                .build();
    }

    @Test
    @DisplayName("Should fetch order successfully when enrichment is enabled")
    void testFetchOrder_WithEnrichmentEnabled_ShouldReturnOrder() {
        // Given
        when(featureProperties.isEnrichRemoteData()).thenReturn(true);
        when(restTemplate.getForObject(anyString(), eq(OrderDto.class))).thenReturn(orderDto);

        // When
        OrderDto result = orderServiceClient.fetchOrder(orderId);

        // Then
        assertNotNull(result);
        assertEquals(orderId, result.getOrderId());
        verify(featureProperties).isEnrichRemoteData();
        verify(restTemplate).getForObject(anyString(), eq(OrderDto.class));
    }

    @Test
    @DisplayName("Should return fallback order when enrichment is disabled")
    void testFetchOrder_WithEnrichmentDisabled_ShouldReturnFallback() {
        // Given
        when(featureProperties.isEnrichRemoteData()).thenReturn(false);

        // When
        OrderDto result = orderServiceClient.fetchOrder(orderId);

        // Then
        assertNotNull(result);
        assertEquals(orderId, result.getOrderId());
        assertTrue(result.getOrderDesc().contains("enrichment-disabled"));
        verify(featureProperties).isEnrichRemoteData();
        verify(restTemplate, never()).getForObject(anyString(), any());
    }

    @Test
    @DisplayName("Should return fallback order when orderId is null")
    void testFetchOrder_WithNullOrderId_ShouldReturnFallback() {
        // When
        OrderDto result = orderServiceClient.fetchOrder(null);

        // Then
        assertNotNull(result);
        assertNull(result.getOrderId());
        assertTrue(result.getOrderDesc().contains("missing-order-id"));
        verify(restTemplate, never()).getForObject(anyString(), any());
    }
}

