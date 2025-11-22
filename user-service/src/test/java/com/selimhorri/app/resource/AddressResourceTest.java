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
import com.selimhorri.app.dto.AddressDto;
import com.selimhorri.app.dto.UserDto;
import com.selimhorri.app.service.AddressService;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@WebMvcTest(AddressResource.class)
@DisplayName("AddressResource Tests")
class AddressResourceTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private AddressService addressService;

    @Autowired
    private ObjectMapper objectMapper;

    private AddressDto testAddressDto;
    private UserDto testUserDto;

    @BeforeEach
    void setUp() {
        testUserDto = UserDto.builder()
                .userId(1)
                .firstName("John")
                .lastName("Doe")
                .email("john.doe@example.com")
                .phone("+1234567890")
                .build();

        testAddressDto = AddressDto.builder()
                .addressId(1)
                .fullAddress("123 Main St")
                .postalCode("12345")
                .city("New York")
                .userDto(testUserDto)
                .build();
    }

    @Test
    @DisplayName("Should return all addresses")
    void testFindAll_ShouldReturnAllAddresses() throws Exception {
        // Given
        List<AddressDto> addresses = Arrays.asList(testAddressDto);
        when(addressService.findAll()).thenReturn(addresses);

        // When & Then
        mockMvc.perform(get("/api/address"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.collection").isArray())
                .andExpect(jsonPath("$.collection[0].addressId").value(1))
                .andExpect(jsonPath("$.collection[0].fullAddress").value("123 Main St"));

        verify(addressService).findAll();
    }

    @Test
    @DisplayName("Should return address by id")
    void testFindById_ShouldReturnAddress() throws Exception {
        // Given
        String addressId = "1";
        when(addressService.findById(1)).thenReturn(testAddressDto);

        // When & Then
        mockMvc.perform(get("/api/address/{addressId}", addressId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.addressId").value(1))
                .andExpect(jsonPath("$.fullAddress").value("123 Main St"));

        verify(addressService).findById(1);
    }

    @Test
    @DisplayName("Should save address")
    void testSave_ShouldCreateAddress() throws Exception {
        // Given
        when(addressService.save(any(AddressDto.class))).thenReturn(testAddressDto);

        // When & Then
        mockMvc.perform(post("/api/address")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(testAddressDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.addressId").value(1))
                .andExpect(jsonPath("$.fullAddress").value("123 Main St"));

        verify(addressService).save(any(AddressDto.class));
    }

    @Test
    @DisplayName("Should update address")
    void testUpdate_ShouldUpdateAddress() throws Exception {
        // Given
        when(addressService.update(any(AddressDto.class))).thenReturn(testAddressDto);

        // When & Then
        mockMvc.perform(put("/api/address")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(testAddressDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.addressId").value(1));

        verify(addressService).update(any(AddressDto.class));
    }

    @Test
    @DisplayName("Should update address by id")
    void testUpdate_WithAddressId_ShouldUpdateAddress() throws Exception {
        // Given
        String addressId = "1";
        when(addressService.update(eq(1), any(AddressDto.class))).thenReturn(testAddressDto);

        // When & Then
        mockMvc.perform(put("/api/address/{addressId}", addressId)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(testAddressDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.addressId").value(1));

        verify(addressService).update(eq(1), any(AddressDto.class));
    }

    @Test
    @DisplayName("Should delete address by id")
    void testDeleteById_ShouldDeleteAddress() throws Exception {
        // Given
        String addressId = "1";
        doNothing().when(addressService).deleteById(1);

        // When & Then
        mockMvc.perform(delete("/api/address/{addressId}", addressId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").value(true));

        verify(addressService).deleteById(1);
    }
}

