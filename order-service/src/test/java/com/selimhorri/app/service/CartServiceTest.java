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

import com.selimhorri.app.client.UserServiceClient;
import com.selimhorri.app.domain.Cart;
import com.selimhorri.app.dto.CartDto;
import com.selimhorri.app.dto.UserDto;
import com.selimhorri.app.exception.wrapper.CartNotFoundException;
import com.selimhorri.app.repository.CartRepository;
import com.selimhorri.app.service.impl.CartServiceImpl;

@ExtendWith(MockitoExtension.class)
@DisplayName("CartService Tests")
class CartServiceTest {

    @Mock
    private CartRepository cartRepository;

    @Mock
    private UserServiceClient userServiceClient;

    @InjectMocks
    private CartServiceImpl cartService;

    private Cart testCart;
    private CartDto testCartDto;
    private UserDto testUserDto;

    @BeforeEach
    void setUp() {
        testCart = Cart.builder()
                .cartId(1)
                .userId(1)
                .build();

        testCartDto = CartDto.builder()
                .cartId(1)
                .userId(1)
                .build();

        testUserDto = UserDto.builder()
                .userId(1)
                .firstName("John")
                .lastName("Doe")
                .build();

        lenient().when(userServiceClient.fetchUser(anyInt())).thenReturn(testUserDto);
    }

    @Test
    @DisplayName("Should return all carts")
    void testFindAll_ShouldReturnAllCarts() {
        // Given
        List<Cart> carts = Arrays.asList(testCart);
        when(cartRepository.findAll()).thenReturn(carts);

        // When
        List<CartDto> result = cartService.findAll();

        // Then
        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals(Integer.valueOf(1), result.get(0).getCartId());
        verify(cartRepository).findAll();
    }

    @Test
    @DisplayName("Should return cart when exists")
    void testFindById_WhenCartExists_ShouldReturnCart() {
        // Given
        Integer cartId = 1;
        when(cartRepository.findById(cartId)).thenReturn(Optional.of(testCart));

        // When
        CartDto result = cartService.findById(cartId);

        // Then
        assertNotNull(result);
        assertEquals(cartId, result.getCartId());
        verify(cartRepository).findById(cartId);
    }

    @Test
    @DisplayName("Should throw exception when cart not exists")
    void testFindById_WhenCartNotExists_ShouldThrowException() {
        // Given
        Integer cartId = 999;
        when(cartRepository.findById(cartId)).thenReturn(Optional.empty());

        // When & Then
        CartNotFoundException exception = assertThrows(
                CartNotFoundException.class,
                () -> cartService.findById(cartId)
        );
        
        assertTrue(exception.getMessage().contains("Cart with id: 999 not found"));
        verify(cartRepository).findById(cartId);
    }

    @Test
    @DisplayName("Should save cart")
    void testSave_ShouldReturnSavedCart() {
        // Given
        when(cartRepository.save(any(Cart.class))).thenReturn(testCart);

        // When
        CartDto result = cartService.save(testCartDto);

        // Then
        assertNotNull(result);
        assertEquals(testCartDto.getCartId(), result.getCartId());
        verify(cartRepository).save(any(Cart.class));
    }

    @Test
    @DisplayName("Should update cart")
    void testUpdate_ShouldReturnUpdatedCart() {
        // Given
        when(cartRepository.save(any(Cart.class))).thenReturn(testCart);

        // When
        CartDto result = cartService.update(testCartDto);

        // Then
        assertNotNull(result);
        assertEquals(testCartDto.getCartId(), result.getCartId());
        verify(cartRepository).save(any(Cart.class));
    }

    @Test
    @DisplayName("Should update cart by id")
    void testUpdate_WithCartId_ShouldReturnUpdatedCart() {
        // Given
        Integer cartId = 1;
        when(cartRepository.findById(cartId)).thenReturn(Optional.of(testCart));
        when(cartRepository.save(any(Cart.class))).thenReturn(testCart);

        // When
        CartDto result = cartService.update(cartId, testCartDto);

        // Then
        assertNotNull(result);
        assertEquals(cartId, result.getCartId());
        verify(cartRepository).findById(cartId);
        verify(cartRepository).save(any(Cart.class));
    }

    @Test
    @DisplayName("Should delete cart by id")
    void testDeleteById_ShouldCallRepositoryDelete() {
        // Given
        Integer cartId = 1;
        doNothing().when(cartRepository).deleteById(cartId);

        // When
        cartService.deleteById(cartId);

        // Then
        verify(cartRepository).deleteById(cartId);
    }
}

