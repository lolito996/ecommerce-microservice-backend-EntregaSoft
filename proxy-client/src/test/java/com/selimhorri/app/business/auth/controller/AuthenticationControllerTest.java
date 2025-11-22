package com.selimhorri.app.business.auth.controller;

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
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import com.selimhorri.app.business.auth.model.request.AuthenticationRequest;
import com.selimhorri.app.business.auth.model.response.AuthenticationResponse;
import com.selimhorri.app.business.auth.service.AuthenticationService;

@ExtendWith(MockitoExtension.class)
@DisplayName("AuthenticationController Tests")
class AuthenticationControllerTest {

    @Mock
    private AuthenticationService authenticationService;

    @InjectMocks
    private AuthenticationController authenticationController;

    private AuthenticationRequest authenticationRequest;
    private AuthenticationResponse authenticationResponse;
    private String jwtToken;

    @BeforeEach
    void setUp() {
        authenticationRequest = new AuthenticationRequest();
        authenticationRequest.setUsername("testuser");
        authenticationRequest.setPassword("password123");

        jwtToken = "test-jwt-token";
        authenticationResponse = new AuthenticationResponse(jwtToken);
    }

    @Test
    @DisplayName("Should authenticate user successfully")
    void testAuthenticate_WithValidRequest_ShouldReturnToken() {
        // Given
        when(authenticationService.authenticate(authenticationRequest)).thenReturn(authenticationResponse);

        // When
        ResponseEntity<AuthenticationResponse> response = authenticationController.authenticate(authenticationRequest);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(jwtToken, response.getBody().getJwt());
        verify(authenticationService).authenticate(authenticationRequest);
    }

    @Test
    @DisplayName("Should validate JWT token")
    void testAuthenticate_WithJwt_ShouldReturnBoolean() {
        // Given
        String jwt = "test-jwt-token";
        when(authenticationService.authenticate(jwt)).thenReturn(true);

        // When
        ResponseEntity<Boolean> response = authenticationController.authenticate(jwt);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody());
        verify(authenticationService).authenticate(jwt);
    }
}

