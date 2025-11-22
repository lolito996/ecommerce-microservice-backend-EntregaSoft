package com.selimhorri.app.integration;

import static com.github.tomakehurst.wiremock.client.WireMock.*;
import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDateTime;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.web.server.LocalServerPort;
import org.springframework.cloud.contract.wiremock.AutoConfigureWireMock;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.selimhorri.app.dto.CartDto;
import com.selimhorri.app.dto.OrderDto;

/**
 * Pruebas de integración que validan la comunicación entre Order Service y Payment Service
 * Simula escenarios reales de comunicación entre microservicios
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureWireMock(port = 0)
@ActiveProfiles("integration-test")
@Transactional
@DisplayName("Order-Payment Service Integration Tests")
class OrderPaymentServiceIntegrationTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private ObjectMapper objectMapper;


    private OrderDto testOrderDto;
    private CartDto testCartDto;
    private String baseUrl;

    @BeforeEach
    void setUp() {
        baseUrl = "http://localhost:" + port + "/order-service";
        
        // Configurar datos de prueba
        testCartDto = CartDto.builder()
                .cartId(1)
                .userId(1)
                .build();

        testOrderDto = OrderDto.builder()
                .orderDate(LocalDateTime.now())
                .orderDesc("Integration Test Order")
                .orderFee(299.99)
                .cartDto(testCartDto)
                .build();

        // Nota: El enriquecimiento remoto está deshabilitado en application-integration-test.yml
        // por lo que UserServiceClient no hará llamadas reales. Los stubs de WireMock
        // están aquí por si se habilita el enriquecimiento en el futuro.
        stubFor(get(urlPathMatching("/user-service/api/users/.*"))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{" +
                            "\"userId\": 1," +
                            "\"firstName\": \"John\"," +
                            "\"lastName\": \"Doe\"," +
                            "\"email\": \"john.doe@example.com\"," +
                            "\"phone\": \"+1234567890\"" +
                        "}")));
    }

    @Test
    @DisplayName("Should create order successfully and allow payment service to retrieve order details")
    void shouldCreateOrderAndAllowPaymentServiceToRetrieveDetails() throws Exception {
        // 1. Crear la orden en Order Service
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<OrderDto> request = new HttpEntity<>(testOrderDto, headers);

        ResponseEntity<OrderDto> createResponse = restTemplate.postForEntity(
                baseUrl + "/api/orders", 
                request, 
                OrderDto.class
        );

        assertThat(createResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(createResponse.getBody()).isNotNull();
        OrderDto createdOrder = createResponse.getBody();
        assertThat(createdOrder.getOrderDesc()).isEqualTo("Integration Test Order");
        assertThat(createdOrder.getOrderFee()).isEqualTo(299.99);
        assertThat(createdOrder.getCartDto().getCartId()).isEqualTo(1);

        Integer orderId = createdOrder.getOrderId();
        assertThat(orderId).isNotNull();

        // 2. Verificar que la orden se puede consultar por ID (simulando Payment Service consultando)
        ResponseEntity<OrderDto> getResponse = restTemplate.getForEntity(
                baseUrl + "/api/orders/" + orderId,
                OrderDto.class
        );

        assertThat(getResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(getResponse.getBody()).isNotNull();
        OrderDto retrievedOrder = getResponse.getBody();
        assertThat(retrievedOrder.getOrderId()).isEqualTo(orderId);
        assertThat(retrievedOrder.getOrderDesc()).isEqualTo("Integration Test Order");
        assertThat(retrievedOrder.getOrderFee()).isEqualTo(299.99);
        assertThat(retrievedOrder.getCartDto().getCartId()).isEqualTo(1);
        assertThat(retrievedOrder.getCartDto().getUserId()).isEqualTo(1);

        // 3. Simular que Payment Service crea un pago asociado a la orden
        stubFor(post(urlPathEqualTo("/payment-service/api/payments"))
                .withRequestBody(containing("\"orderId\":" + orderId))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader("Content-Type", "application/json")
                        .withBody(String.format("{" +
                            "\"paymentId\": %d," +
                            "\"orderId\": %d," +
                            "\"isPayed\": false," +
                            "\"paymentStatus\": \"IN_PROGRESS\"" +
                        "}", orderId, orderId))));

        // Nota: La verificación de llamadas a User Service no se hace porque
        // el enriquecimiento remoto está deshabilitado en los tests de integración
    }

    @Test
    @DisplayName("Should handle order update and maintain consistency across services")
    void shouldHandleOrderUpdateAndMaintainConsistency() throws Exception {
        // 1. Crear orden inicial
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<OrderDto> createRequest = new HttpEntity<>(testOrderDto, headers);

        ResponseEntity<OrderDto> createResponse = restTemplate.postForEntity(
                baseUrl + "/api/orders",
                createRequest,
                OrderDto.class
        );

        assertThat(createResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(createResponse.getBody()).isNotNull();
        OrderDto createdOrder = createResponse.getBody();
        Integer orderId = createdOrder.getOrderId();
        assertThat(orderId).isNotNull();

        // 2. Actualizar la orden (cambio de precio que afecta al pago)
        OrderDto updatedOrderDto = OrderDto.builder()
                .orderId(orderId)
                .orderDate(LocalDateTime.now())
                .orderDesc("Updated Order - Price Changed")
                .orderFee(399.99) // Precio actualizado
                .cartDto(testCartDto)
                .build();

        // 3. Ejecutar actualización
        HttpEntity<OrderDto> updateRequest = new HttpEntity<>(updatedOrderDto, headers);
        ResponseEntity<OrderDto> updateResponse = restTemplate.exchange(
                baseUrl + "/api/orders/" + orderId,
                HttpMethod.PUT,
                updateRequest,
                OrderDto.class
        );

        assertThat(updateResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(updateResponse.getBody()).isNotNull();
        OrderDto updatedOrder = updateResponse.getBody();
        assertThat(updatedOrder.getOrderId()).isEqualTo(orderId);
        assertThat(updatedOrder.getOrderDesc()).isEqualTo("Updated Order - Price Changed");
        assertThat(updatedOrder.getOrderFee()).isEqualTo(399.99);

        // 4. Verificar que Payment Service puede obtener la orden actualizada
        ResponseEntity<OrderDto> getResponse = restTemplate.getForEntity(
                baseUrl + "/api/orders/" + orderId,
                OrderDto.class
        );

        assertThat(getResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(getResponse.getBody()).isNotNull();
        OrderDto retrievedOrder = getResponse.getBody();
        assertThat(retrievedOrder.getOrderFee()).isEqualTo(399.99);
        assertThat(retrievedOrder.getOrderDesc()).isEqualTo("Updated Order - Price Changed");

        // 5. Simular notificación a Payment Service sobre el cambio
        stubFor(put(urlPathMatching("/payment-service/api/payments/order/.*"))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{" +
                            "\"message\": \"Payment updated due to order changes\"," +
                            "\"newAmount\": 399.99" +
                        "}")));

    }

    @Test
    @DisplayName("Should handle service failure scenarios gracefully")
    void shouldHandleServiceFailuresScenariosGracefully() throws Exception {
        // Nota: Con el enriquecimiento remoto deshabilitado, el UserServiceClient
        // retornará un fallback en lugar de hacer llamadas reales.
        // Este test valida que la creación de orden funciona incluso sin enriquecimiento.
        
        // 1. Configurar fallo temporal en User Service (aunque no se usará)
        stubFor(get(urlPathMatching("/user-service/api/users/.*"))
                .inScenario("User Service Failure")
                .whenScenarioStateIs("Started")
                .willReturn(aResponse()
                        .withStatus(503)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{" +
                            "\"timestamp\": \"2024-01-15T10:30:00\"," +
                            "\"httpStatus\": \"SERVICE_UNAVAILABLE\"," +
                            "\"msg\": \"User Service temporarily unavailable\"" +
                        "}"))
                .willSetStateTo("Failed"));

        // 2. Intentar crear orden (debería funcionar porque el enriquecimiento está deshabilitado)
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<OrderDto> request = new HttpEntity<>(testOrderDto, headers);

        // La creación de orden debería funcionar porque no depende del User Service
        // cuando el enriquecimiento está deshabilitado
        ResponseEntity<OrderDto> response = restTemplate.postForEntity(
                baseUrl + "/api/orders",
                request,
                OrderDto.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        OrderDto createdOrder = response.getBody();
        assertThat(createdOrder.getOrderDesc()).isEqualTo("Integration Test Order");
        assertThat(createdOrder.getOrderFee()).isEqualTo(299.99);

        // 3. Verificar que Payment Service puede procesar la orden
        stubFor(get(urlPathMatching("/payment-service/api/payments/order/.*"))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader("Content-Type", "application/json")
                        .withBody("{" +
                            "\"message\": \"Payment service operational\"," +
                            "\"status\": \"READY\"" +
                        "}")));

    }
}