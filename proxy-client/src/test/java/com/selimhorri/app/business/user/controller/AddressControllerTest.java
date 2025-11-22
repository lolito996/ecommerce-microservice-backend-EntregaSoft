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

import com.selimhorri.app.business.user.model.AddressDto;
import com.selimhorri.app.business.user.model.response.AddressUserServiceCollectionDtoResponse;
import com.selimhorri.app.business.user.service.AddressClientService;

@ExtendWith(MockitoExtension.class)
@DisplayName("AddressController Tests")
class AddressControllerTest {

    @Mock
    private AddressClientService addressClientService;

    @InjectMocks
    private AddressController addressController;

    private AddressDto addressDto;
    private AddressUserServiceCollectionDtoResponse collectionResponse;

    @BeforeEach
    void setUp() {
        addressDto = new AddressDto();
        addressDto.setAddressId(1);
        addressDto.setFullAddress("123 Main St");

        collectionResponse = new AddressUserServiceCollectionDtoResponse();
    }

    @Test
    @DisplayName("Should find all addresses")
    void testFindAll_ShouldReturnAddresses() {
        // Given
        ResponseEntity<AddressUserServiceCollectionDtoResponse> serviceResponse = 
                ResponseEntity.ok(collectionResponse);
        when(addressClientService.findAll()).thenReturn(serviceResponse);

        // When
        ResponseEntity<AddressUserServiceCollectionDtoResponse> response = addressController.findAll();

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(addressClientService).findAll();
    }

    @Test
    @DisplayName("Should find address by id")
    void testFindById_ShouldReturnAddress() {
        // Given
        String addressId = "1";
        ResponseEntity<AddressDto> serviceResponse = ResponseEntity.ok(addressDto);
        when(addressClientService.findById(addressId)).thenReturn(serviceResponse);

        // When
        ResponseEntity<AddressDto> response = addressController.findById(addressId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        verify(addressClientService).findById(addressId);
    }

    @Test
    @DisplayName("Should save address")
    void testSave_ShouldReturnSavedAddress() {
        // Given
        ResponseEntity<AddressDto> serviceResponse = ResponseEntity.ok(addressDto);
        when(addressClientService.save(addressDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<AddressDto> response = addressController.save(addressDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(addressClientService).save(addressDto);
    }

    @Test
    @DisplayName("Should update address")
    void testUpdate_ShouldReturnUpdatedAddress() {
        // Given
        ResponseEntity<AddressDto> serviceResponse = ResponseEntity.ok(addressDto);
        when(addressClientService.update(addressDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<AddressDto> response = addressController.update(addressDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(addressClientService).update(addressDto);
    }

    @Test
    @DisplayName("Should update address by id")
    void testUpdate_WithAddressId_ShouldReturnUpdatedAddress() {
        // Given
        String addressId = "1";
        ResponseEntity<AddressDto> serviceResponse = ResponseEntity.ok(addressDto);
        when(addressClientService.update(addressDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<AddressDto> response = addressController.update(addressId, addressDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(addressClientService).update(addressDto);
    }

    @Test
    @DisplayName("Should delete address by id")
    void testDeleteById_ShouldReturnTrue() {
        // Given
        String addressId = "1";
        ResponseEntity<Boolean> serviceResponse = ResponseEntity.ok(true);
        when(addressClientService.deleteById(addressId)).thenReturn(serviceResponse);

        // When
        ResponseEntity<Boolean> response = addressController.deleteById(addressId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody());
        verify(addressClientService).deleteById(addressId);
    }
}

