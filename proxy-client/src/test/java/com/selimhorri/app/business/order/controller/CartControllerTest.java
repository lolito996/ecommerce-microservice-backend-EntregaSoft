package com.selimhorri.app.business.order.controller;

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

import com.selimhorri.app.business.order.model.CartDto;
import com.selimhorri.app.business.order.model.response.CartOrderServiceDtoCollectionResponse;
import com.selimhorri.app.business.order.service.CartClientService;

@ExtendWith(MockitoExtension.class)
@DisplayName("CartController Tests")
class CartControllerTest {

    @Mock
    private CartClientService cartClientService;

    @InjectMocks
    private CartController cartController;

    private CartDto cartDto;
    private CartOrderServiceDtoCollectionResponse collectionResponse;

    @BeforeEach
    void setUp() {
        cartDto = new CartDto();
        cartDto.setCartId(1);
        cartDto.setUserId(1);

        collectionResponse = new CartOrderServiceDtoCollectionResponse();
    }

    @Test
    @DisplayName("Should find all carts")
    void testFindAll_ShouldReturnCarts() {
        // Given
        ResponseEntity<CartOrderServiceDtoCollectionResponse> serviceResponse = 
                ResponseEntity.ok(collectionResponse);
        when(cartClientService.findAll()).thenReturn(serviceResponse);

        // When
        ResponseEntity<CartOrderServiceDtoCollectionResponse> response = cartController.findAll();

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(cartClientService).findAll();
    }

    @Test
    @DisplayName("Should find cart by id")
    void testFindById_ShouldReturnCart() {
        // Given
        String cartId = "1";
        ResponseEntity<CartDto> serviceResponse = ResponseEntity.ok(cartDto);
        when(cartClientService.findById(cartId)).thenReturn(serviceResponse);

        // When
        ResponseEntity<CartDto> response = cartController.findById(cartId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        verify(cartClientService).findById(cartId);
    }

    @Test
    @DisplayName("Should save cart")
    void testSave_ShouldReturnSavedCart() {
        // Given
        ResponseEntity<CartDto> serviceResponse = ResponseEntity.ok(cartDto);
        when(cartClientService.save(cartDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<CartDto> response = cartController.save(cartDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(cartClientService).save(cartDto);
    }

    @Test
    @DisplayName("Should update cart")
    void testUpdate_ShouldReturnUpdatedCart() {
        // Given
        ResponseEntity<CartDto> serviceResponse = ResponseEntity.ok(cartDto);
        when(cartClientService.update(cartDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<CartDto> response = cartController.update(cartDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(cartClientService).update(cartDto);
    }

    @Test
    @DisplayName("Should update cart by id")
    void testUpdate_WithCartId_ShouldReturnUpdatedCart() {
        // Given
        String cartId = "1";
        ResponseEntity<CartDto> serviceResponse = ResponseEntity.ok(cartDto);
        when(cartClientService.update(cartId, cartDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<CartDto> response = cartController.update(cartId, cartDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(cartClientService).update(cartId, cartDto);
    }

    @Test
    @DisplayName("Should delete cart by id")
    void testDeleteById_ShouldReturnTrue() {
        // Given
        String cartId = "1";
        ResponseEntity<Boolean> serviceResponse = ResponseEntity.ok(true);
        when(cartClientService.deleteById(cartId)).thenReturn(serviceResponse);

        // When
        ResponseEntity<Boolean> response = cartController.deleteById(cartId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody());
        verify(cartClientService).deleteById(cartId);
    }
}

