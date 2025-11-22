package com.selimhorri.app.business.auth.service;

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
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;

import com.selimhorri.app.business.auth.model.request.AuthenticationRequest;
import com.selimhorri.app.business.auth.model.response.AuthenticationResponse;
import com.selimhorri.app.business.auth.service.impl.AuthenticationServiceImpl;
import com.selimhorri.app.exception.wrapper.IllegalAuthenticationCredentialsException;
import com.selimhorri.app.jwt.service.JwtService;

@ExtendWith(MockitoExtension.class)
@DisplayName("AuthenticationService Tests")
class AuthenticationServiceTest {

    @Mock
    private AuthenticationManager authenticationManager;

    @Mock
    private UserDetailsService userDetailsService;

    @Mock
    private JwtService jwtService;

    @InjectMocks
    private AuthenticationServiceImpl authenticationService;

    private AuthenticationRequest authenticationRequest;
    private UserDetails userDetails;
    private String jwtToken;

    @BeforeEach
    void setUp() {
        authenticationRequest = new AuthenticationRequest();
        authenticationRequest.setUsername("testuser");
        authenticationRequest.setPassword("password123");

        userDetails = User.builder()
                .username("testuser")
                .password("password123")
                .authorities("ROLE_USER")
                .build();

        jwtToken = "test-jwt-token";
    }

    @Test
    @DisplayName("Should authenticate successfully with valid credentials")
    void testAuthenticate_WithValidCredentials_ShouldReturnToken() {
        // Given
        doNothing().when(authenticationManager).authenticate(any(UsernamePasswordAuthenticationToken.class));
        when(userDetailsService.loadUserByUsername("testuser")).thenReturn(userDetails);
        when(jwtService.generateToken(userDetails)).thenReturn(jwtToken);

        // When
        AuthenticationResponse response = authenticationService.authenticate(authenticationRequest);

        // Then
        assertNotNull(response);
        assertEquals(jwtToken, response.getJwt());
        verify(authenticationManager).authenticate(any(UsernamePasswordAuthenticationToken.class));
        verify(userDetailsService).loadUserByUsername("testuser");
        verify(jwtService).generateToken(userDetails);
    }

    @Test
    @DisplayName("Should throw exception with invalid credentials")
    void testAuthenticate_WithInvalidCredentials_ShouldThrowException() {
        // Given
        doThrow(new BadCredentialsException("Bad credentials"))
                .when(authenticationManager).authenticate(any(UsernamePasswordAuthenticationToken.class));

        // When & Then
        IllegalAuthenticationCredentialsException exception = assertThrows(
                IllegalAuthenticationCredentialsException.class,
                () -> authenticationService.authenticate(authenticationRequest)
        );

        assertEquals("#### Bad credentials! ####", exception.getMessage());
        verify(authenticationManager).authenticate(any(UsernamePasswordAuthenticationToken.class));
        verify(userDetailsService, never()).loadUserByUsername(anyString());
        verify(jwtService, never()).generateToken(any());
    }

    @Test
    @DisplayName("Should return null when authenticating with JWT")
    void testAuthenticate_WithJwt_ShouldReturnNull() {
        // When
        Boolean result = authenticationService.authenticate("test-jwt-token");

        // Then
        assertNull(result);
    }
}

