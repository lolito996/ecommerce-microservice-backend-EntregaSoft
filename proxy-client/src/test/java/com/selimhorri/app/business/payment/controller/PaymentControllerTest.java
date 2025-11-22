package com.selimhorri.app.business.payment.controller;

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

import com.selimhorri.app.business.payment.model.PaymentDto;
import com.selimhorri.app.business.payment.model.response.PaymentPaymentServiceDtoCollectionResponse;
import com.selimhorri.app.business.payment.service.PaymentClientService;

@ExtendWith(MockitoExtension.class)
@DisplayName("PaymentController Tests")
class PaymentControllerTest {

    @Mock
    private PaymentClientService paymentClientService;

    @InjectMocks
    private PaymentController paymentController;

    private PaymentDto paymentDto;
    private PaymentPaymentServiceDtoCollectionResponse collectionResponse;

    @BeforeEach
    void setUp() {
        paymentDto = new PaymentDto();
        paymentDto.setPaymentId(1);
        paymentDto.setIsPayed(false);

        collectionResponse = new PaymentPaymentServiceDtoCollectionResponse();
    }

    @Test
    @DisplayName("Should find all payments")
    void testFindAll_ShouldReturnPayments() {
        // Given
        ResponseEntity<PaymentPaymentServiceDtoCollectionResponse> serviceResponse = 
                ResponseEntity.ok(collectionResponse);
        when(paymentClientService.findAll()).thenReturn(serviceResponse);

        // When
        ResponseEntity<PaymentPaymentServiceDtoCollectionResponse> response = paymentController.findAll();

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(paymentClientService).findAll();
    }

    @Test
    @DisplayName("Should find payment by id")
    void testFindById_ShouldReturnPayment() {
        // Given
        String paymentId = "1";
        ResponseEntity<PaymentDto> serviceResponse = ResponseEntity.ok(paymentDto);
        when(paymentClientService.findById(paymentId)).thenReturn(serviceResponse);

        // When
        ResponseEntity<PaymentDto> response = paymentController.findById(paymentId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        verify(paymentClientService).findById(paymentId);
    }

    @Test
    @DisplayName("Should save payment")
    void testSave_ShouldReturnSavedPayment() {
        // Given
        ResponseEntity<PaymentDto> serviceResponse = ResponseEntity.ok(paymentDto);
        when(paymentClientService.save(paymentDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<PaymentDto> response = paymentController.save(paymentDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(paymentClientService).save(paymentDto);
    }

    @Test
    @DisplayName("Should update payment")
    void testUpdate_ShouldReturnUpdatedPayment() {
        // Given
        ResponseEntity<PaymentDto> serviceResponse = ResponseEntity.ok(paymentDto);
        when(paymentClientService.update(paymentDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<PaymentDto> response = paymentController.update(paymentDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(paymentClientService).update(paymentDto);
    }

    @Test
    @DisplayName("Should delete payment by id")
    void testDeleteById_ShouldReturnTrue() {
        // Given
        String paymentId = "1";
        ResponseEntity<Boolean> serviceResponse = ResponseEntity.ok(true);
        when(paymentClientService.deleteById(paymentId)).thenReturn(serviceResponse);

        // When
        ResponseEntity<Boolean> response = paymentController.deleteById(paymentId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody());
        verify(paymentClientService).deleteById(paymentId);
    }
}

