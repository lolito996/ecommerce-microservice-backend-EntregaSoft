package com.selimhorri.app.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.selimhorri.app.domain.Credential;
import com.selimhorri.app.domain.RoleBasedAuthority;
import com.selimhorri.app.domain.VerificationToken;
import com.selimhorri.app.dto.CredentialDto;
import com.selimhorri.app.dto.VerificationTokenDto;
import com.selimhorri.app.exception.wrapper.VerificationTokenNotFoundException;
import com.selimhorri.app.repository.VerificationTokenRepository;
import com.selimhorri.app.service.impl.VerificationTokenServiceImpl;

@ExtendWith(MockitoExtension.class)
@DisplayName("VerificationTokenService Tests")
class VerificationTokenServiceTest {

    @Mock
    private VerificationTokenRepository verificationTokenRepository;

    @InjectMocks
    private VerificationTokenServiceImpl verificationTokenService;

    private VerificationToken testVerificationToken;
    private VerificationTokenDto testVerificationTokenDto;
    private Credential testCredential;
    private CredentialDto testCredentialDto;

    @BeforeEach
    void setUp() {
        testCredential = Credential.builder()
                .credentialId(1)
                .username("testuser")
                .password("password123")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();

        testCredentialDto = CredentialDto.builder()
                .credentialId(1)
                .username("testuser")
                .password("password123")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();

        testVerificationToken = VerificationToken.builder()
                .verificationTokenId(1)
                .token("test-token-123")
                .expireDate(LocalDate.now().plusDays(1))
                .credential(testCredential)
                .build();

        testVerificationTokenDto = VerificationTokenDto.builder()
                .verificationTokenId(1)
                .token("test-token-123")
                .expireDate(LocalDate.now().plusDays(1))
                .credentialDto(testCredentialDto)
                .build();
    }

    @Test
    @DisplayName("Should return all verification tokens")
    void testFindAll_ShouldReturnAllVerificationTokens() {
        // Given
        List<VerificationToken> tokens = Arrays.asList(testVerificationToken);
        when(verificationTokenRepository.findAll()).thenReturn(tokens);

        // When
        List<VerificationTokenDto> result = verificationTokenService.findAll();

        // Then
        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("test-token-123", result.get(0).getToken());
        verify(verificationTokenRepository).findAll();
    }

    @Test
    @DisplayName("Should return verification token when exists")
    void testFindById_WhenTokenExists_ShouldReturnToken() {
        // Given
        Integer tokenId = 1;
        when(verificationTokenRepository.findById(tokenId)).thenReturn(Optional.of(testVerificationToken));

        // When
        VerificationTokenDto result = verificationTokenService.findById(tokenId);

        // Then
        assertNotNull(result);
        assertEquals(tokenId, result.getVerificationTokenId());
        assertEquals("test-token-123", result.getToken());
        verify(verificationTokenRepository).findById(tokenId);
    }

    @Test
    @DisplayName("Should throw exception when verification token not exists")
    void testFindById_WhenTokenNotExists_ShouldThrowException() {
        // Given
        Integer tokenId = 999;
        when(verificationTokenRepository.findById(tokenId)).thenReturn(Optional.empty());

        // When & Then
        VerificationTokenNotFoundException exception = assertThrows(
                VerificationTokenNotFoundException.class,
                () -> verificationTokenService.findById(tokenId)
        );
        
        assertTrue(exception.getMessage().contains("VerificationToken with id: 999 not found"));
        verify(verificationTokenRepository).findById(tokenId);
    }

    @Test
    @DisplayName("Should save verification token")
    void testSave_ShouldReturnSavedToken() {
        // Given
        when(verificationTokenRepository.save(any(VerificationToken.class))).thenReturn(testVerificationToken);

        // When
        VerificationTokenDto result = verificationTokenService.save(testVerificationTokenDto);

        // Then
        assertNotNull(result);
        assertEquals(testVerificationTokenDto.getVerificationTokenId(), result.getVerificationTokenId());
        assertEquals(testVerificationTokenDto.getToken(), result.getToken());
        verify(verificationTokenRepository).save(any(VerificationToken.class));
    }

    @Test
    @DisplayName("Should update verification token")
    void testUpdate_ShouldReturnUpdatedToken() {
        // Given
        when(verificationTokenRepository.save(any(VerificationToken.class))).thenReturn(testVerificationToken);

        // When
        VerificationTokenDto result = verificationTokenService.update(testVerificationTokenDto);

        // Then
        assertNotNull(result);
        assertEquals(testVerificationTokenDto.getVerificationTokenId(), result.getVerificationTokenId());
        verify(verificationTokenRepository).save(any(VerificationToken.class));
    }

    @Test
    @DisplayName("Should update verification token by id")
    void testUpdate_WithTokenId_ShouldReturnUpdatedToken() {
        // Given
        Integer tokenId = 1;
        when(verificationTokenRepository.findById(tokenId)).thenReturn(Optional.of(testVerificationToken));
        when(verificationTokenRepository.save(any(VerificationToken.class))).thenReturn(testVerificationToken);

        // When
        VerificationTokenDto result = verificationTokenService.update(tokenId, testVerificationTokenDto);

        // Then
        assertNotNull(result);
        assertEquals(tokenId, result.getVerificationTokenId());
        verify(verificationTokenRepository).findById(tokenId);
        verify(verificationTokenRepository).save(any(VerificationToken.class));
    }

    @Test
    @DisplayName("Should delete verification token by id")
    void testDeleteById_ShouldCallRepositoryDelete() {
        // Given
        Integer tokenId = 1;
        doNothing().when(verificationTokenRepository).deleteById(tokenId);

        // When
        verificationTokenService.deleteById(tokenId);

        // Then
        verify(verificationTokenRepository).deleteById(tokenId);
    }
}

