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

import com.selimhorri.app.business.user.model.VerificationTokenDto;
import com.selimhorri.app.business.user.model.response.VerificationUserTokenServiceCollectionDtoResponse;
import com.selimhorri.app.business.user.service.VerificationTokenClientService;

@ExtendWith(MockitoExtension.class)
@DisplayName("VerificationTokenController Tests")
class VerificationTokenControllerTest {

    @Mock
    private VerificationTokenClientService verificationTokenClientService;

    @InjectMocks
    private VerificationTokenController verificationTokenController;

    private VerificationTokenDto verificationTokenDto;
    private VerificationUserTokenServiceCollectionDtoResponse collectionResponse;

    @BeforeEach
    void setUp() {
        verificationTokenDto = new VerificationTokenDto();
        verificationTokenDto.setVerificationTokenId(1);
        verificationTokenDto.setToken("test-token-123");

        collectionResponse = new VerificationUserTokenServiceCollectionDtoResponse();
    }

    @Test
    @DisplayName("Should find all verification tokens")
    void testFindAll_ShouldReturnTokens() {
        // Given
        ResponseEntity<VerificationUserTokenServiceCollectionDtoResponse> serviceResponse = 
                ResponseEntity.ok(collectionResponse);
        when(verificationTokenClientService.findAll()).thenReturn(serviceResponse);

        // When
        ResponseEntity<VerificationUserTokenServiceCollectionDtoResponse> response = 
                verificationTokenController.findAll();

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(verificationTokenClientService).findAll();
    }

    @Test
    @DisplayName("Should find verification token by id")
    void testFindById_ShouldReturnToken() {
        // Given
        String tokenId = "1";
        ResponseEntity<VerificationTokenDto> serviceResponse = ResponseEntity.ok(verificationTokenDto);
        when(verificationTokenClientService.findById(tokenId)).thenReturn(serviceResponse);

        // When
        ResponseEntity<VerificationTokenDto> response = verificationTokenController.findById(tokenId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        verify(verificationTokenClientService).findById(tokenId);
    }

    @Test
    @DisplayName("Should save verification token")
    void testSave_ShouldReturnSavedToken() {
        // Given
        ResponseEntity<VerificationTokenDto> serviceResponse = ResponseEntity.ok(verificationTokenDto);
        when(verificationTokenClientService.save(verificationTokenDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<VerificationTokenDto> response = verificationTokenController.save(verificationTokenDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(verificationTokenClientService).save(verificationTokenDto);
    }

    @Test
    @DisplayName("Should update verification token")
    void testUpdate_ShouldReturnUpdatedToken() {
        // Given
        ResponseEntity<VerificationTokenDto> serviceResponse = ResponseEntity.ok(verificationTokenDto);
        when(verificationTokenClientService.update(verificationTokenDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<VerificationTokenDto> response = verificationTokenController.update(verificationTokenDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(verificationTokenClientService).update(verificationTokenDto);
    }

    @Test
    @DisplayName("Should update verification token by id")
    void testUpdate_WithTokenId_ShouldReturnUpdatedToken() {
        // Given
        String tokenId = "1";
        ResponseEntity<VerificationTokenDto> serviceResponse = ResponseEntity.ok(verificationTokenDto);
        when(verificationTokenClientService.update(verificationTokenDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<VerificationTokenDto> response = 
                verificationTokenController.update(tokenId, verificationTokenDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(verificationTokenClientService).update(verificationTokenDto);
    }

    @Test
    @DisplayName("Should delete verification token by id")
    void testDeleteById_ShouldReturnTrue() {
        // Given
        String tokenId = "1";
        ResponseEntity<Boolean> serviceResponse = ResponseEntity.ok(true);
        when(verificationTokenClientService.deleteById(tokenId)).thenReturn(serviceResponse);

        // When
        ResponseEntity<Boolean> response = verificationTokenController.deleteById(tokenId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody());
        verify(verificationTokenClientService).deleteById(tokenId);
    }
}

