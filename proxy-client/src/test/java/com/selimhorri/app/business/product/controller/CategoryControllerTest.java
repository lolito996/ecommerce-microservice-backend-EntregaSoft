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

import com.selimhorri.app.business.product.model.CategoryDto;
import com.selimhorri.app.business.product.model.response.CategoryProductServiceCollectionDtoResponse;
import com.selimhorri.app.business.product.service.CategoryClientService;

@ExtendWith(MockitoExtension.class)
@DisplayName("CategoryController Tests")
class CategoryControllerTest {

    @Mock
    private CategoryClientService categoryClientService;

    @InjectMocks
    private CategoryController categoryController;

    private CategoryDto categoryDto;
    private CategoryProductServiceCollectionDtoResponse collectionResponse;

    @BeforeEach
    void setUp() {
        categoryDto = new CategoryDto();
        categoryDto.setCategoryId(1);
        categoryDto.setCategoryTitle("Test Category");

        collectionResponse = new CategoryProductServiceCollectionDtoResponse();
    }

    @Test
    @DisplayName("Should find all categories")
    void testFindAll_ShouldReturnCategories() {
        // Given
        ResponseEntity<CategoryProductServiceCollectionDtoResponse> serviceResponse = 
                ResponseEntity.ok(collectionResponse);
        when(categoryClientService.findAll()).thenReturn(serviceResponse);

        // When
        ResponseEntity<CategoryProductServiceCollectionDtoResponse> response = categoryController.findAll();

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(categoryClientService).findAll();
    }

    @Test
    @DisplayName("Should find category by id")
    void testFindById_ShouldReturnCategory() {
        // Given
        String categoryId = "1";
        ResponseEntity<CategoryDto> serviceResponse = ResponseEntity.ok(categoryDto);
        when(categoryClientService.findById(categoryId)).thenReturn(serviceResponse);

        // When
        ResponseEntity<CategoryDto> response = categoryController.findById(categoryId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        verify(categoryClientService).findById(categoryId);
    }

    @Test
    @DisplayName("Should save category")
    void testSave_ShouldReturnSavedCategory() {
        // Given
        ResponseEntity<CategoryDto> serviceResponse = ResponseEntity.ok(categoryDto);
        when(categoryClientService.save(categoryDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<CategoryDto> response = categoryController.save(categoryDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(categoryClientService).save(categoryDto);
    }

    @Test
    @DisplayName("Should update category")
    void testUpdate_ShouldReturnUpdatedCategory() {
        // Given
        ResponseEntity<CategoryDto> serviceResponse = ResponseEntity.ok(categoryDto);
        when(categoryClientService.update(categoryDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<CategoryDto> response = categoryController.update(categoryDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(categoryClientService).update(categoryDto);
    }

    @Test
    @DisplayName("Should update category by id")
    void testUpdate_WithCategoryId_ShouldReturnUpdatedCategory() {
        // Given
        String categoryId = "1";
        ResponseEntity<CategoryDto> serviceResponse = ResponseEntity.ok(categoryDto);
        when(categoryClientService.update(categoryId, categoryDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<CategoryDto> response = categoryController.update(categoryId, categoryDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(categoryClientService).update(categoryId, categoryDto);
    }

    @Test
    @DisplayName("Should delete category by id")
    void testDeleteById_ShouldReturnTrue() {
        // Given
        String categoryId = "1";
        ResponseEntity<Boolean> serviceResponse = ResponseEntity.ok(true);
        when(categoryClientService.deleteById(categoryId)).thenReturn(serviceResponse);

        // When
        ResponseEntity<Boolean> response = categoryController.deleteById(categoryId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody());
        verify(categoryClientService).deleteById(categoryId);
    }
}

