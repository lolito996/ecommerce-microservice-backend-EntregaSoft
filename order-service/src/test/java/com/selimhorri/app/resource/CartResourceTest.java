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
import com.selimhorri.app.dto.CartDto;
import com.selimhorri.app.service.CartService;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@WebMvcTest(CartResource.class)
@DisplayName("CartResource Tests")
class CartResourceTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private CartService cartService;

    @Autowired
    private ObjectMapper objectMapper;

    private CartDto testCartDto;

    @BeforeEach
    void setUp() {
        testCartDto = CartDto.builder()
                .cartId(1)
                .userId(1)
                .build();
    }

    @Test
    @DisplayName("Should return all carts")
    void testFindAll_ShouldReturnAllCarts() throws Exception {
        // Given
        List<CartDto> carts = Arrays.asList(testCartDto);
        when(cartService.findAll()).thenReturn(carts);

        // When & Then
        mockMvc.perform(get("/api/carts"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.collection").isArray())
                .andExpect(jsonPath("$.collection[0].cartId").value(1))
                .andExpect(jsonPath("$.collection[0].userId").value(1));

        verify(cartService).findAll();
    }

    @Test
    @DisplayName("Should return cart by id")
    void testFindById_ShouldReturnCart() throws Exception {
        // Given
        String cartId = "1";
        when(cartService.findById(1)).thenReturn(testCartDto);

        // When & Then
        mockMvc.perform(get("/api/carts/{cartId}", cartId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.cartId").value(1))
                .andExpect(jsonPath("$.userId").value(1));

        verify(cartService).findById(1);
    }

    @Test
    @DisplayName("Should save cart")
    void testSave_ShouldCreateCart() throws Exception {
        // Given
        when(cartService.save(any(CartDto.class))).thenReturn(testCartDto);

        // When & Then
        mockMvc.perform(post("/api/carts")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(testCartDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.cartId").value(1))
                .andExpect(jsonPath("$.userId").value(1));

        verify(cartService).save(any(CartDto.class));
    }

    @Test
    @DisplayName("Should update cart")
    void testUpdate_ShouldUpdateCart() throws Exception {
        // Given
        when(cartService.update(any(CartDto.class))).thenReturn(testCartDto);

        // When & Then
        mockMvc.perform(put("/api/carts")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(testCartDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.cartId").value(1));

        verify(cartService).update(any(CartDto.class));
    }

    @Test
    @DisplayName("Should update cart by id")
    void testUpdate_WithCartId_ShouldUpdateCart() throws Exception {
        // Given
        String cartId = "1";
        when(cartService.update(eq(1), any(CartDto.class))).thenReturn(testCartDto);

        // When & Then
        mockMvc.perform(put("/api/carts/{cartId}", cartId)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(testCartDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.cartId").value(1));

        verify(cartService).update(eq(1), any(CartDto.class));
    }

    @Test
    @DisplayName("Should delete cart by id")
    void testDeleteById_ShouldDeleteCart() throws Exception {
        // Given
        String cartId = "1";
        doNothing().when(cartService).deleteById(1);

        // When & Then
        mockMvc.perform(delete("/api/carts/{cartId}", cartId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").value(true));

        verify(cartService).deleteById(1);
    }
}

