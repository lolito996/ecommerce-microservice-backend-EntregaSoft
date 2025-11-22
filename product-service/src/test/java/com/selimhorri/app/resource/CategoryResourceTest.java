package com.selimhorri.app.resource;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import java.util.Arrays;
import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.selimhorri.app.dto.CategoryDto;
import com.selimhorri.app.service.CategoryService;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@WebMvcTest(CategoryResource.class)
@DisplayName("CategoryResource Tests")
class CategoryResourceTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private CategoryService categoryService;

    @Autowired
    private ObjectMapper objectMapper;

    private CategoryDto testCategoryDto;

    @BeforeEach
    void setUp() {
        testCategoryDto = CategoryDto.builder()
                .categoryId(1)
                .categoryTitle("Test Category")
                .imageUrl("http://example.com/image.jpg")
                .build();
    }

    @Test
    @DisplayName("Should return all categories")
    void testFindAll_ShouldReturnAllCategories() throws Exception {
        // Given
        List<CategoryDto> categories = Arrays.asList(testCategoryDto);
        when(categoryService.findAll()).thenReturn(categories);

        // When & Then
        mockMvc.perform(get("/api/categories"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.collection").isArray())
                .andExpect(jsonPath("$.collection[0].categoryId").value(1))
                .andExpect(jsonPath("$.collection[0].categoryTitle").value("Test Category"));

        verify(categoryService).findAll();
    }

    @Test
    @DisplayName("Should return category by id")
    void testFindById_ShouldReturnCategory() throws Exception {
        // Given
        String categoryId = "1";
        when(categoryService.findById(1)).thenReturn(testCategoryDto);

        // When & Then
        mockMvc.perform(get("/api/categories/{categoryId}", categoryId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.categoryId").value(1))
                .andExpect(jsonPath("$.categoryTitle").value("Test Category"));

        verify(categoryService).findById(1);
    }

    @Test
    @DisplayName("Should save category")
    void testSave_ShouldCreateCategory() throws Exception {
        // Given
        when(categoryService.save(any(CategoryDto.class))).thenReturn(testCategoryDto);

        // When & Then
        mockMvc.perform(post("/api/categories")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(testCategoryDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.categoryId").value(1))
                .andExpect(jsonPath("$.categoryTitle").value("Test Category"));

        verify(categoryService).save(any(CategoryDto.class));
    }

    @Test
    @DisplayName("Should update category")
    void testUpdate_ShouldUpdateCategory() throws Exception {
        // Given
        when(categoryService.update(any(CategoryDto.class))).thenReturn(testCategoryDto);

        // When & Then
        mockMvc.perform(put("/api/categories")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(testCategoryDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.categoryId").value(1));

        verify(categoryService).update(any(CategoryDto.class));
    }

    @Test
    @DisplayName("Should update category by id")
    void testUpdate_WithCategoryId_ShouldUpdateCategory() throws Exception {
        // Given
        String categoryId = "1";
        when(categoryService.update(eq(1), any(CategoryDto.class))).thenReturn(testCategoryDto);

        // When & Then
        mockMvc.perform(put("/api/categories/{categoryId}", categoryId)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(testCategoryDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.categoryId").value(1));

        verify(categoryService).update(eq(1), any(CategoryDto.class));
    }

    @Test
    @DisplayName("Should delete category by id")
    void testDeleteById_ShouldDeleteCategory() throws Exception {
        // Given
        String categoryId = "1";
        doNothing().when(categoryService).deleteById(1);

        // When & Then
        mockMvc.perform(delete("/api/categories/{categoryId}", categoryId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").value(true));

        verify(categoryService).deleteById(1);
    }
}

