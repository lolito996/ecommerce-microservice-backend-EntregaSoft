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

import com.selimhorri.app.domain.Category;
import com.selimhorri.app.dto.CategoryDto;
import com.selimhorri.app.exception.wrapper.CategoryNotFoundException;
import com.selimhorri.app.repository.CategoryRepository;
import com.selimhorri.app.service.impl.CategoryServiceImpl;

@ExtendWith(MockitoExtension.class)
@DisplayName("CategoryService Tests")
class CategoryServiceTest {

    @Mock
    private CategoryRepository categoryRepository;

    @InjectMocks
    private CategoryServiceImpl categoryService;

    private Category testCategory;
    private CategoryDto testCategoryDto;

    @BeforeEach
    void setUp() {
        testCategory = Category.builder()
                .categoryId(1)
                .categoryTitle("Test Category")
                .imageUrl("http://example.com/image.jpg")
                .build();

        testCategoryDto = CategoryDto.builder()
                .categoryId(1)
                .categoryTitle("Test Category")
                .imageUrl("http://example.com/image.jpg")
                .build();
    }

    @Test
    @DisplayName("Should return all categories")
    void testFindAll_ShouldReturnAllCategories() {
        // Given
        List<Category> categories = Arrays.asList(testCategory);
        when(categoryRepository.findAll()).thenReturn(categories);

        // When
        List<CategoryDto> result = categoryService.findAll();

        // Then
        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("Test Category", result.get(0).getCategoryTitle());
        verify(categoryRepository).findAll();
    }

    @Test
    @DisplayName("Should return category when exists")
    void testFindById_WhenCategoryExists_ShouldReturnCategory() {
        // Given
        Integer categoryId = 1;
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(testCategory));

        // When
        CategoryDto result = categoryService.findById(categoryId);

        // Then
        assertNotNull(result);
        assertEquals(categoryId, result.getCategoryId());
        assertEquals("Test Category", result.getCategoryTitle());
        verify(categoryRepository).findById(categoryId);
    }

    @Test
    @DisplayName("Should throw exception when category not exists")
    void testFindById_WhenCategoryNotExists_ShouldThrowException() {
        // Given
        Integer categoryId = 999;
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.empty());

        // When & Then
        CategoryNotFoundException exception = assertThrows(
                CategoryNotFoundException.class,
                () -> categoryService.findById(categoryId)
        );
        
        assertTrue(exception.getMessage().contains("Category with id: 999 not found"));
        verify(categoryRepository).findById(categoryId);
    }

    @Test
    @DisplayName("Should save category")
    void testSave_ShouldReturnSavedCategory() {
        // Given
        when(categoryRepository.save(any(Category.class))).thenReturn(testCategory);

        // When
        CategoryDto result = categoryService.save(testCategoryDto);

        // Then
        assertNotNull(result);
        assertEquals(testCategoryDto.getCategoryId(), result.getCategoryId());
        assertEquals(testCategoryDto.getCategoryTitle(), result.getCategoryTitle());
        verify(categoryRepository).save(any(Category.class));
    }

    @Test
    @DisplayName("Should update category")
    void testUpdate_ShouldReturnUpdatedCategory() {
        // Given
        when(categoryRepository.save(any(Category.class))).thenReturn(testCategory);

        // When
        CategoryDto result = categoryService.update(testCategoryDto);

        // Then
        assertNotNull(result);
        assertEquals(testCategoryDto.getCategoryId(), result.getCategoryId());
        verify(categoryRepository).save(any(Category.class));
    }

    @Test
    @DisplayName("Should update category by id")
    void testUpdate_WithCategoryId_ShouldReturnUpdatedCategory() {
        // Given
        Integer categoryId = 1;
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(testCategory));
        when(categoryRepository.save(any(Category.class))).thenReturn(testCategory);

        // When
        CategoryDto result = categoryService.update(categoryId, testCategoryDto);

        // Then
        assertNotNull(result);
        assertEquals(categoryId, result.getCategoryId());
        verify(categoryRepository).findById(categoryId);
        verify(categoryRepository).save(any(Category.class));
    }

    @Test
    @DisplayName("Should delete category by id")
    void testDeleteById_ShouldCallRepositoryDelete() {
        // Given
        Integer categoryId = 1;
        doNothing().when(categoryRepository).deleteById(categoryId);

        // When
        categoryService.deleteById(categoryId);

        // Then
        verify(categoryRepository).deleteById(categoryId);
    }
}

