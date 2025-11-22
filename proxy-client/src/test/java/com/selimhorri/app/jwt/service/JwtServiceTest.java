package com.selimhorri.app.jwt.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import java.util.Date;
import java.util.function.Function;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;

import com.selimhorri.app.jwt.service.impl.JwtServiceImpl;
import com.selimhorri.app.jwt.util.JwtUtil;

import io.jsonwebtoken.Claims;

@ExtendWith(MockitoExtension.class)
@DisplayName("JwtService Tests")
class JwtServiceTest {

    @Mock
    private JwtUtil jwtUtil;

    @InjectMocks
    private JwtServiceImpl jwtService;

    private UserDetails userDetails;
    private String token;
    private String username;
    private Date expiration;

    @BeforeEach
    void setUp() {
        userDetails = User.builder()
                .username("testuser")
                .password("password123")
                .authorities("ROLE_USER")
                .build();

        token = "test-jwt-token";
        username = "testuser";
        expiration = new Date(System.currentTimeMillis() + 3600000);
    }

    @Test
    @DisplayName("Should extract username from token")
    void testExtractUsername_ShouldReturnUsername() {
        // Given
        when(jwtUtil.extractUsername(token)).thenReturn(username);

        // When
        String result = jwtService.extractUsername(token);

        // Then
        assertNotNull(result);
        assertEquals(username, result);
        verify(jwtUtil).extractUsername(token);
    }

    @Test
    @DisplayName("Should extract expiration from token")
    void testExtractExpiration_ShouldReturnDate() {
        // Given
        when(jwtUtil.extractExpiration(token)).thenReturn(expiration);

        // When
        Date result = jwtService.extractExpiration(token);

        // Then
        assertNotNull(result);
        assertEquals(expiration, result);
        verify(jwtUtil).extractExpiration(token);
    }

    @Test
    @DisplayName("Should extract claims from token")
    void testExtractClaims_ShouldReturnClaim() {
        // Given
        Function<Claims, String> claimsResolver = Claims::getSubject;
        String expectedClaim = "testuser";
        when(jwtUtil.extractClaims(eq(token), any(Function.class))).thenReturn(expectedClaim);

        // When
        String result = jwtService.extractClaims(token, claimsResolver);

        // Then
        assertNotNull(result);
        assertEquals(expectedClaim, result);
        verify(jwtUtil).extractClaims(eq(token), any(Function.class));
    }

    @Test
    @DisplayName("Should generate token from user details")
    void testGenerateToken_ShouldReturnToken() {
        // Given
        String expectedToken = "generated-token";
        when(jwtUtil.generateToken(userDetails)).thenReturn(expectedToken);

        // When
        String result = jwtService.generateToken(userDetails);

        // Then
        assertNotNull(result);
        assertEquals(expectedToken, result);
        verify(jwtUtil).generateToken(userDetails);
    }

    @Test
    @DisplayName("Should validate token successfully")
    void testValidateToken_WithValidToken_ShouldReturnTrue() {
        // Given
        when(jwtUtil.validateToken(token, userDetails)).thenReturn(true);

        // When
        Boolean result = jwtService.validateToken(token, userDetails);

        // Then
        assertNotNull(result);
        assertTrue(result);
        verify(jwtUtil).validateToken(token, userDetails);
    }

    @Test
    @DisplayName("Should return false for invalid token")
    void testValidateToken_WithInvalidToken_ShouldReturnFalse() {
        // Given
        when(jwtUtil.validateToken(token, userDetails)).thenReturn(false);

        // When
        Boolean result = jwtService.validateToken(token, userDetails);

        // Then
        assertNotNull(result);
        assertFalse(result);
        verify(jwtUtil).validateToken(token, userDetails);
    }
}

