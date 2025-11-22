package com.selimhorri.app.business.user.controller;

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

import com.selimhorri.app.business.user.model.CredentialDto;
import com.selimhorri.app.business.user.model.response.CredentialUserServiceCollectionDtoResponse;
import com.selimhorri.app.business.user.service.CredentialClientService;

@ExtendWith(MockitoExtension.class)
@DisplayName("CredentialController Tests")
class CredentialControllerTest {

    @Mock
    private CredentialClientService credentialClientService;

    @InjectMocks
    private CredentialController credentialController;

    private CredentialDto credentialDto;
    private CredentialUserServiceCollectionDtoResponse collectionResponse;

    @BeforeEach
    void setUp() {
        credentialDto = new CredentialDto();
        credentialDto.setCredentialId(1);
        credentialDto.setUsername("testuser");

        collectionResponse = new CredentialUserServiceCollectionDtoResponse();
    }

    @Test
    @DisplayName("Should find all credentials")
    void testFindAll_ShouldReturnCredentials() {
        // Given
        ResponseEntity<CredentialUserServiceCollectionDtoResponse> serviceResponse = 
                ResponseEntity.ok(collectionResponse);
        when(credentialClientService.findAll()).thenReturn(serviceResponse);

        // When
        ResponseEntity<CredentialUserServiceCollectionDtoResponse> response = credentialController.findAll();

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(credentialClientService).findAll();
    }

    @Test
    @DisplayName("Should find credential by id")
    void testFindById_ShouldReturnCredential() {
        // Given
        String credentialId = "1";
        ResponseEntity<CredentialDto> serviceResponse = ResponseEntity.ok(credentialDto);
        when(credentialClientService.findById(credentialId)).thenReturn(serviceResponse);

        // When
        ResponseEntity<CredentialDto> response = credentialController.findById(credentialId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        verify(credentialClientService).findById(credentialId);
    }

    @Test
    @DisplayName("Should find credential by username")
    void testFindByCredentialname_ShouldReturnCredential() {
        // Given
        String username = "testuser";
        ResponseEntity<CredentialDto> serviceResponse = ResponseEntity.ok(credentialDto);
        when(credentialClientService.findByUsername(username)).thenReturn(serviceResponse);

        // When
        ResponseEntity<CredentialDto> response = credentialController.findByCredentialname(username);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(credentialClientService).findByUsername(username);
    }

    @Test
    @DisplayName("Should save credential")
    void testSave_ShouldReturnSavedCredential() {
        // Given
        ResponseEntity<CredentialDto> serviceResponse = ResponseEntity.ok(credentialDto);
        when(credentialClientService.save(credentialDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<CredentialDto> response = credentialController.save(credentialDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(credentialClientService).save(credentialDto);
    }

    @Test
    @DisplayName("Should update credential")
    void testUpdate_ShouldReturnUpdatedCredential() {
        // Given
        ResponseEntity<CredentialDto> serviceResponse = ResponseEntity.ok(credentialDto);
        when(credentialClientService.update(credentialDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<CredentialDto> response = credentialController.update(credentialDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(credentialClientService).update(credentialDto);
    }

    @Test
    @DisplayName("Should update credential by id")
    void testUpdate_WithCredentialId_ShouldReturnUpdatedCredential() {
        // Given
        String credentialId = "1";
        ResponseEntity<CredentialDto> serviceResponse = ResponseEntity.ok(credentialDto);
        when(credentialClientService.update(credentialDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<CredentialDto> response = 
                credentialController.update(credentialId, credentialDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(credentialClientService).update(credentialDto);
    }

    @Test
    @DisplayName("Should delete credential by id")
    void testDeleteById_ShouldReturnTrue() {
        // Given
        String credentialId = "1";
        ResponseEntity<Boolean> serviceResponse = ResponseEntity.ok(true);
        when(credentialClientService.deleteById(credentialId)).thenReturn(serviceResponse);

        // When
        ResponseEntity<Boolean> response = credentialController.deleteById(credentialId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody());
        verify(credentialClientService).deleteById(credentialId);
    }
}

