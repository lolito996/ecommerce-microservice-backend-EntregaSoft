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
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import com.selimhorri.app.config.properties.AppFeatureProperties;
import com.selimhorri.app.dto.UserDto;

@ExtendWith(MockitoExtension.class)
@DisplayName("UserServiceClient Tests")
class UserServiceClientTest {

    @Mock
    private RestTemplate restTemplate;

    @Mock
    private AppFeatureProperties featureProperties;

    @InjectMocks
    private UserServiceClient userServiceClient;

    private UserDto userDto;
    private Integer userId;

    @BeforeEach
    void setUp() {
        userId = 1;
        userDto = UserDto.builder()
                .userId(userId)
                .firstName("John")
                .lastName("Doe")
                .email("john.doe@example.com")
                .build();
    }

    @Test
    @DisplayName("Should fetch user successfully when enrichment is enabled")
    void testFetchUser_WithEnrichmentEnabled_ShouldReturnUser() {
        // Given
        when(featureProperties.isEnrichRemoteData()).thenReturn(true);
        when(restTemplate.getForObject(anyString(), eq(UserDto.class))).thenReturn(userDto);

        // When
        UserDto result = userServiceClient.fetchUser(userId);

        // Then
        assertNotNull(result);
        assertEquals(userId, result.getUserId());
        assertEquals("John", result.getFirstName());
        verify(featureProperties).isEnrichRemoteData();
        verify(restTemplate).getForObject(anyString(), eq(UserDto.class));
    }

    @Test
    @DisplayName("Should return fallback user when enrichment is disabled")
    void testFetchUser_WithEnrichmentDisabled_ShouldReturnFallback() {
        // Given
        when(featureProperties.isEnrichRemoteData()).thenReturn(false);

        // When
        UserDto result = userServiceClient.fetchUser(userId);

        // Then
        assertNotNull(result);
        assertEquals(userId, result.getUserId());
        assertEquals("N/A", result.getFirstName());
        assertEquals("enrichment-disabled", result.getLastName());
        verify(featureProperties).isEnrichRemoteData();
        verify(restTemplate, never()).getForObject(anyString(), any());
    }

    @Test
    @DisplayName("Should return fallback user when userId is null")
    void testFetchUser_WithNullUserId_ShouldReturnFallback() {
        // When
        UserDto result = userServiceClient.fetchUser(null);

        // Then
        assertNotNull(result);
        assertNull(result.getUserId());
        assertEquals("N/A", result.getFirstName());
        assertEquals("missing-user-id", result.getLastName());
        verify(restTemplate, never()).getForObject(anyString(), any());
    }

    @Test
    @DisplayName("Should throw exception when service throws exception (Circuit Breaker not active in unit test)")
    void testFetchUser_WhenServiceThrowsException_ShouldThrowException() {
        // Given
        when(featureProperties.isEnrichRemoteData()).thenReturn(true);
        when(restTemplate.getForObject(anyString(), eq(UserDto.class)))
                .thenThrow(new RestClientException("Service unavailable"));

        // When & Then
        // Note: Circuit Breaker fallback only works in Spring context with AOP enabled.
        // In unit tests, the exception will propagate. The fallback will be tested in integration tests.
        assertThrows(RestClientException.class, () -> {
            userServiceClient.fetchUser(userId);
        });
        
        verify(featureProperties).isEnrichRemoteData();
        verify(restTemplate).getForObject(anyString(), eq(UserDto.class));
    }
}

