package com.selimhorri.app.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

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
import com.selimhorri.app.dto.CredentialDto;
import com.selimhorri.app.exception.wrapper.CredentialNotFoundException;
import com.selimhorri.app.exception.wrapper.UserObjectNotFoundException;
import com.selimhorri.app.repository.CredentialRepository;
import com.selimhorri.app.service.impl.CredentialServiceImpl;

@ExtendWith(MockitoExtension.class)
@DisplayName("CredentialService Tests")
class CredentialServiceTest {

    @Mock
    private CredentialRepository credentialRepository;

    @InjectMocks
    private CredentialServiceImpl credentialService;

    private Credential testCredential;
    private CredentialDto testCredentialDto;
    private com.selimhorri.app.domain.User testUser;
    private com.selimhorri.app.dto.UserDto testUserDto;

    @BeforeEach
    void setUp() {
        testUser = com.selimhorri.app.domain.User.builder()
                .userId(1)
                .firstName("John")
                .lastName("Doe")
                .email("john.doe@example.com")
                .phone("+1234567890")
                .build();

        testUserDto = com.selimhorri.app.dto.UserDto.builder()
                .userId(1)
                .firstName("John")
                .lastName("Doe")
                .email("john.doe@example.com")
                .phone("+1234567890")
                .build();

        testCredential = Credential.builder()
                .credentialId(1)
                .username("testuser")
                .password("password123")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .user(testUser)
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
                .userDto(testUserDto)
                .build();
    }

    @Test
    @DisplayName("Should return all credentials")
    void testFindAll_ShouldReturnAllCredentials() {
        // Given
        List<Credential> credentials = Arrays.asList(testCredential);
        when(credentialRepository.findAll()).thenReturn(credentials);

        // When
        List<CredentialDto> result = credentialService.findAll();

        // Then
        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("testuser", result.get(0).getUsername());
        verify(credentialRepository).findAll();
    }

    @Test
    @DisplayName("Should return credential when exists")
    void testFindById_WhenCredentialExists_ShouldReturnCredential() {
        // Given
        Integer credentialId = 1;
        when(credentialRepository.findById(credentialId)).thenReturn(Optional.of(testCredential));

        // When
        CredentialDto result = credentialService.findById(credentialId);

        // Then
        assertNotNull(result);
        assertEquals(credentialId, result.getCredentialId());
        assertEquals("testuser", result.getUsername());
        verify(credentialRepository).findById(credentialId);
    }

    @Test
    @DisplayName("Should throw exception when credential not exists")
    void testFindById_WhenCredentialNotExists_ShouldThrowException() {
        // Given
        Integer credentialId = 999;
        when(credentialRepository.findById(credentialId)).thenReturn(Optional.empty());

        // When & Then
        CredentialNotFoundException exception = assertThrows(
                CredentialNotFoundException.class,
                () -> credentialService.findById(credentialId)
        );
        
        assertTrue(exception.getMessage().contains("Credential with id: 999 not found"));
        verify(credentialRepository).findById(credentialId);
    }

    @Test
    @DisplayName("Should save credential")
    void testSave_ShouldReturnSavedCredential() {
        // Given
        when(credentialRepository.save(any(Credential.class))).thenReturn(testCredential);

        // When
        CredentialDto result = credentialService.save(testCredentialDto);

        // Then
        assertNotNull(result);
        assertEquals(testCredentialDto.getCredentialId(), result.getCredentialId());
        assertEquals(testCredentialDto.getUsername(), result.getUsername());
        verify(credentialRepository).save(any(Credential.class));
    }

    @Test
    @DisplayName("Should update credential")
    void testUpdate_ShouldReturnUpdatedCredential() {
        // Given
        when(credentialRepository.save(any(Credential.class))).thenReturn(testCredential);

        // When
        CredentialDto result = credentialService.update(testCredentialDto);

        // Then
        assertNotNull(result);
        assertEquals(testCredentialDto.getCredentialId(), result.getCredentialId());
        verify(credentialRepository).save(any(Credential.class));
    }

    @Test
    @DisplayName("Should update credential by id")
    void testUpdate_WithCredentialId_ShouldReturnUpdatedCredential() {
        // Given
        Integer credentialId = 1;
        when(credentialRepository.findById(credentialId)).thenReturn(Optional.of(testCredential));
        when(credentialRepository.save(any(Credential.class))).thenReturn(testCredential);

        // When
        CredentialDto result = credentialService.update(credentialId, testCredentialDto);

        // Then
        assertNotNull(result);
        assertEquals(credentialId, result.getCredentialId());
        verify(credentialRepository).findById(credentialId);
        verify(credentialRepository).save(any(Credential.class));
    }

    @Test
    @DisplayName("Should delete credential by id")
    void testDeleteById_ShouldCallRepositoryDelete() {
        // Given
        Integer credentialId = 1;
        doNothing().when(credentialRepository).deleteById(credentialId);

        // When
        credentialService.deleteById(credentialId);

        // Then
        verify(credentialRepository).deleteById(credentialId);
    }

    @Test
    @DisplayName("Should find credential by username")
    void testFindByUsername_WhenCredentialExists_ShouldReturnCredential() {
        // Given
        String username = "testuser";
        when(credentialRepository.findByUsername(username)).thenReturn(Optional.of(testCredential));

        // When
        CredentialDto result = credentialService.findByUsername(username);

        // Then
        assertNotNull(result);
        assertEquals(username, result.getUsername());
        verify(credentialRepository).findByUsername(username);
    }

    @Test
    @DisplayName("Should throw exception when credential by username not exists")
    void testFindByUsername_WhenCredentialNotExists_ShouldThrowException() {
        // Given
        String username = "nonexistent";
        when(credentialRepository.findByUsername(username)).thenReturn(Optional.empty());

        // When & Then
        UserObjectNotFoundException exception = assertThrows(
                UserObjectNotFoundException.class,
                () -> credentialService.findByUsername(username)
        );
        
        assertTrue(exception.getMessage().contains("Credential with username: nonexistent not found"));
        verify(credentialRepository).findByUsername(username);
    }
}

