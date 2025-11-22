package com.selimhorri.app.business.orderItem.controller;

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

import com.selimhorri.app.business.orderItem.model.OrderItemDto;
import com.selimhorri.app.business.orderItem.model.OrderItemId;
import com.selimhorri.app.business.orderItem.model.response.OrderItemOrderItemServiceDtoCollectionResponse;
import com.selimhorri.app.business.orderItem.service.OrderItemClientService;

@ExtendWith(MockitoExtension.class)
@DisplayName("OrderItemController Tests")
class OrderItemControllerTest {

    @Mock
    private OrderItemClientService orderItemClientService;

    @InjectMocks
    private OrderItemController orderItemController;

    private OrderItemDto orderItemDto;
    private OrderItemId orderItemId;
    private OrderItemOrderItemServiceDtoCollectionResponse collectionResponse;

    @BeforeEach
    void setUp() {
        orderItemId = new OrderItemId(1, 1);
        orderItemDto = new OrderItemDto();
        orderItemDto.setOrderId(1);
        orderItemDto.setProductId(1);
        orderItemDto.setOrderedQuantity(2);

        collectionResponse = new OrderItemOrderItemServiceDtoCollectionResponse();
    }

    @Test
    @DisplayName("Should find all order items")
    void testFindAll_ShouldReturnOrderItems() {
        // Given
        ResponseEntity<OrderItemOrderItemServiceDtoCollectionResponse> serviceResponse = 
                ResponseEntity.ok(collectionResponse);
        when(orderItemClientService.findAll()).thenReturn(serviceResponse);

        // When
        ResponseEntity<OrderItemOrderItemServiceDtoCollectionResponse> response = orderItemController.findAll();

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(orderItemClientService).findAll();
    }

    @Test
    @DisplayName("Should find order item by path variables")
    void testFindById_WithPathVariables_ShouldReturnOrderItem() {
        // Given
        String orderId = "1";
        String productId = "1";
        ResponseEntity<OrderItemDto> serviceResponse = ResponseEntity.ok(orderItemDto);
        when(orderItemClientService.findById(any(OrderItemId.class))).thenReturn(serviceResponse);

        // When
        ResponseEntity<OrderItemDto> response = orderItemController.findById(orderId, productId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        verify(orderItemClientService).findById(any(OrderItemId.class));
    }

    @Test
    @DisplayName("Should find order item by request body")
    void testFindById_WithRequestBody_ShouldReturnOrderItem() {
        // Given
        ResponseEntity<OrderItemDto> serviceResponse = ResponseEntity.ok(orderItemDto);
        when(orderItemClientService.findById(orderItemId)).thenReturn(serviceResponse);

        // When
        ResponseEntity<OrderItemDto> response = orderItemController.findById(orderItemId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        verify(orderItemClientService).findById(orderItemId);
    }

    @Test
    @DisplayName("Should save order item")
    void testSave_ShouldReturnSavedOrderItem() {
        // Given
        ResponseEntity<OrderItemDto> serviceResponse = ResponseEntity.ok(orderItemDto);
        when(orderItemClientService.save(orderItemDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<OrderItemDto> response = orderItemController.save(orderItemDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(orderItemClientService).save(orderItemDto);
    }

    @Test
    @DisplayName("Should update order item")
    void testUpdate_ShouldReturnUpdatedOrderItem() {
        // Given
        ResponseEntity<OrderItemDto> serviceResponse = ResponseEntity.ok(orderItemDto);
        when(orderItemClientService.update(orderItemDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<OrderItemDto> response = orderItemController.update(orderItemDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(orderItemClientService).update(orderItemDto);
    }

    @Test
    @DisplayName("Should delete order item by path variables")
    void testDeleteById_WithPathVariables_ShouldReturnTrue() {
        // Given
        String orderId = "1";
        String productId = "1";
        ResponseEntity<Boolean> serviceResponse = ResponseEntity.ok(true);
        when(orderItemClientService.deleteById(any(OrderItemId.class))).thenReturn(serviceResponse);

        // When
        ResponseEntity<Boolean> response = orderItemController.deleteById(orderId, productId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody());
        verify(orderItemClientService).deleteById(any(OrderItemId.class));
    }

    @Test
    @DisplayName("Should delete order item by request body")
    void testDeleteById_WithRequestBody_ShouldReturnTrue() {
        // Given
        ResponseEntity<Boolean> serviceResponse = ResponseEntity.ok(true);
        when(orderItemClientService.deleteById(orderItemId)).thenReturn(serviceResponse);

        // When
        ResponseEntity<Boolean> response = orderItemController.deleteById(orderItemId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody());
        verify(orderItemClientService).deleteById(orderItemId);
    }
}

