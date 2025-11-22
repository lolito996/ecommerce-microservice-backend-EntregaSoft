package com.selimhorri.app.business.product.controller;

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

import com.selimhorri.app.business.product.model.ProductDto;
import com.selimhorri.app.business.product.model.response.ProductProductServiceCollectionDtoResponse;
import com.selimhorri.app.business.product.service.ProductClientService;

@ExtendWith(MockitoExtension.class)
@DisplayName("ProductController Tests")
class ProductControllerTest {

    @Mock
    private ProductClientService productClientService;

    @InjectMocks
    private ProductController productController;

    private ProductDto productDto;
    private ProductProductServiceCollectionDtoResponse collectionResponse;

    @BeforeEach
    void setUp() {
        productDto = new ProductDto();
        productDto.setProductId(1);
        productDto.setProductTitle("Test Product");

        collectionResponse = new ProductProductServiceCollectionDtoResponse();
    }

    @Test
    @DisplayName("Should find all products")
    void testFindAll_ShouldReturnProducts() {
        // Given
        ResponseEntity<ProductProductServiceCollectionDtoResponse> serviceResponse = 
                ResponseEntity.ok(collectionResponse);
        when(productClientService.findAll()).thenReturn(serviceResponse);

        // When
        ResponseEntity<ProductProductServiceCollectionDtoResponse> response = productController.findAll();

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(productClientService).findAll();
    }

    @Test
    @DisplayName("Should find product by id")
    void testFindById_ShouldReturnProduct() {
        // Given
        String productId = "1";
        ResponseEntity<ProductDto> serviceResponse = ResponseEntity.ok(productDto);
        when(productClientService.findById(productId)).thenReturn(serviceResponse);

        // When
        ResponseEntity<ProductDto> response = productController.findById(productId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        verify(productClientService).findById(productId);
    }

    @Test
    @DisplayName("Should save product")
    void testSave_ShouldReturnSavedProduct() {
        // Given
        ResponseEntity<ProductDto> serviceResponse = ResponseEntity.ok(productDto);
        when(productClientService.save(productDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<ProductDto> response = productController.save(productDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(productClientService).save(productDto);
    }

    @Test
    @DisplayName("Should update product")
    void testUpdate_ShouldReturnUpdatedProduct() {
        // Given
        ResponseEntity<ProductDto> serviceResponse = ResponseEntity.ok(productDto);
        when(productClientService.update(productDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<ProductDto> response = productController.update(productDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(productClientService).update(productDto);
    }

    @Test
    @DisplayName("Should update product by id")
    void testUpdate_WithProductId_ShouldReturnUpdatedProduct() {
        // Given
        String productId = "1";
        ResponseEntity<ProductDto> serviceResponse = ResponseEntity.ok(productDto);
        when(productClientService.update(productId, productDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<ProductDto> response = productController.update(productId, productDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(productClientService).update(productId, productDto);
    }

    @Test
    @DisplayName("Should delete product by id")
    void testDeleteById_ShouldReturnTrue() {
        // Given
        String productId = "1";
        ResponseEntity<Boolean> serviceResponse = ResponseEntity.ok(true);
        when(productClientService.deleteById(productId)).thenReturn(serviceResponse);

        // When
        ResponseEntity<Boolean> response = productController.deleteById(productId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody());
        verify(productClientService).deleteById(productId);
    }
}

