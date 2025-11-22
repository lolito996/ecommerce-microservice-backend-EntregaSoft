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
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import com.selimhorri.app.business.auth.service.impl.UserDetailsServiceImpl;
import com.selimhorri.app.business.user.model.CredentialDto;
import com.selimhorri.app.business.user.model.RoleBasedAuthority;

@ExtendWith(MockitoExtension.class)
@DisplayName("UserDetailsService Tests")
class UserDetailsServiceTest {

    @Mock
    private RestTemplate restTemplate;

    @InjectMocks
    private UserDetailsServiceImpl userDetailsService;

    private CredentialDto credentialDto;
    private String username;

    @BeforeEach
    void setUp() {
        username = "testuser";

        credentialDto = CredentialDto.builder()
                .credentialId(1)
                .username(username)
                .password("password123")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();
    }

    @Test
    @DisplayName("Should load user by username successfully")
    void testLoadUserByUsername_WithValidUsername_ShouldReturnUserDetails() {
        // Given
        when(restTemplate.getForObject(anyString(), eq(CredentialDto.class)))
                .thenReturn(credentialDto);

        // When
        UserDetails result = userDetailsService.loadUserByUsername(username);

        // Then
        assertNotNull(result);
        assertEquals(username, result.getUsername());
        assertTrue(result.isEnabled());
        assertTrue(result.isAccountNonExpired());
        assertTrue(result.isAccountNonLocked());
        assertTrue(result.isCredentialsNonExpired());
        verify(restTemplate).getForObject(anyString(), eq(CredentialDto.class));
    }

}

