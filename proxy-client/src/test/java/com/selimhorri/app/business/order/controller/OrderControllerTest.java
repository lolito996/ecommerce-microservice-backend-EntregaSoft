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

import com.selimhorri.app.business.order.model.OrderDto;
import com.selimhorri.app.business.order.model.response.OrderOrderServiceDtoCollectionResponse;
import com.selimhorri.app.business.order.service.OrderClientService;

@ExtendWith(MockitoExtension.class)
@DisplayName("OrderController Tests")
class OrderControllerTest {

    @Mock
    private OrderClientService orderClientService;

    @InjectMocks
    private OrderController orderController;

    private OrderDto orderDto;
    private OrderOrderServiceDtoCollectionResponse collectionResponse;

    @BeforeEach
    void setUp() {
        orderDto = new OrderDto();
        orderDto.setOrderId(1);
        orderDto.setOrderDesc("Test Order");

        collectionResponse = new OrderOrderServiceDtoCollectionResponse();
    }

    @Test
    @DisplayName("Should find all orders")
    void testFindAll_ShouldReturnOrders() {
        // Given
        ResponseEntity<OrderOrderServiceDtoCollectionResponse> serviceResponse = 
                ResponseEntity.ok(collectionResponse);
        when(orderClientService.findAll()).thenReturn(serviceResponse);

        // When
        ResponseEntity<OrderOrderServiceDtoCollectionResponse> response = orderController.findAll();

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(orderClientService).findAll();
    }

    @Test
    @DisplayName("Should find order by id")
    void testFindById_ShouldReturnOrder() {
        // Given
        String orderId = "1";
        ResponseEntity<OrderDto> serviceResponse = ResponseEntity.ok(orderDto);
        when(orderClientService.findById(orderId)).thenReturn(serviceResponse);

        // When
        ResponseEntity<OrderDto> response = orderController.findById(orderId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        verify(orderClientService).findById(orderId);
    }

    @Test
    @DisplayName("Should save order")
    void testSave_ShouldReturnSavedOrder() {
        // Given
        ResponseEntity<OrderDto> serviceResponse = ResponseEntity.ok(orderDto);
        when(orderClientService.save(orderDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<OrderDto> response = orderController.save(orderDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(orderClientService).save(orderDto);
    }

    @Test
    @DisplayName("Should update order")
    void testUpdate_ShouldReturnUpdatedOrder() {
        // Given
        ResponseEntity<OrderDto> serviceResponse = ResponseEntity.ok(orderDto);
        when(orderClientService.update(orderDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<OrderDto> response = orderController.update(orderDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(orderClientService).update(orderDto);
    }

    @Test
    @DisplayName("Should update order by id")
    void testUpdate_WithOrderId_ShouldReturnUpdatedOrder() {
        // Given
        String orderId = "1";
        ResponseEntity<OrderDto> serviceResponse = ResponseEntity.ok(orderDto);
        when(orderClientService.update(orderId, orderDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<OrderDto> response = orderController.update(orderId, orderDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(orderClientService).update(orderId, orderDto);
    }

    @Test
    @DisplayName("Should delete order by id")
    void testDeleteById_ShouldReturnTrue() {
        // Given
        String orderId = "1";
        ResponseEntity<Boolean> serviceResponse = ResponseEntity.ok(true);
        when(orderClientService.deleteById(orderId)).thenReturn(serviceResponse);

        // When
        ResponseEntity<Boolean> response = orderController.deleteById(orderId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody());
        verify(orderClientService).deleteById(orderId);
    }
}

