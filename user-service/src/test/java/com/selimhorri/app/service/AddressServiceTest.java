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

import com.selimhorri.app.domain.Address;
import com.selimhorri.app.dto.AddressDto;
import com.selimhorri.app.exception.wrapper.AddressNotFoundException;
import com.selimhorri.app.repository.AddressRepository;
import com.selimhorri.app.service.impl.AddressServiceImpl;

@ExtendWith(MockitoExtension.class)
@DisplayName("AddressService Tests")
class AddressServiceTest {

    @Mock
    private AddressRepository addressRepository;

    @InjectMocks
    private AddressServiceImpl addressService;

    private Address testAddress;
    private AddressDto testAddressDto;
    private com.selimhorri.app.domain.User testUser;
    private com.selimhorri.app.dto.UserDto testUserDto;

    @BeforeEach
    void setUp() {
        testUser = com.selimhorri.app.domain.User.builder()
                .userId(1)
                .firstName("John")
                .lastName("Doe")
                .email("john.doe@example.com")
                .phone("+1234567890")
                .build();

        testUserDto = com.selimhorri.app.dto.UserDto.builder()
                .userId(1)
                .firstName("John")
                .lastName("Doe")
                .email("john.doe@example.com")
                .phone("+1234567890")
                .build();

        testAddress = Address.builder()
                .addressId(1)
                .fullAddress("123 Main St")
                .postalCode("12345")
                .city("New York")
                .user(testUser)
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
    void testFindAll_ShouldReturnAllAddresses() {
        // Given
        List<Address> addresses = Arrays.asList(testAddress);
        when(addressRepository.findAll()).thenReturn(addresses);

        // When
        List<AddressDto> result = addressService.findAll();

        // Then
        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("123 Main St", result.get(0).getFullAddress());
        verify(addressRepository).findAll();
    }

    @Test
    @DisplayName("Should return address when exists")
    void testFindById_WhenAddressExists_ShouldReturnAddress() {
        // Given
        Integer addressId = 1;
        when(addressRepository.findById(addressId)).thenReturn(Optional.of(testAddress));

        // When
        AddressDto result = addressService.findById(addressId);

        // Then
        assertNotNull(result);
        assertEquals(addressId, result.getAddressId());
        assertEquals("123 Main St", result.getFullAddress());
        verify(addressRepository).findById(addressId);
    }

    @Test
    @DisplayName("Should throw exception when address not exists")
    void testFindById_WhenAddressNotExists_ShouldThrowException() {
        // Given
        Integer addressId = 999;
        when(addressRepository.findById(addressId)).thenReturn(Optional.empty());

        // When & Then
        AddressNotFoundException exception = assertThrows(
                AddressNotFoundException.class,
                () -> addressService.findById(addressId)
        );
        
        assertTrue(exception.getMessage().contains("Address with id: 999 not found"));
        verify(addressRepository).findById(addressId);
    }

    @Test
    @DisplayName("Should save address")
    void testSave_ShouldReturnSavedAddress() {
        // Given
        when(addressRepository.save(any(Address.class))).thenReturn(testAddress);

        // When
        AddressDto result = addressService.save(testAddressDto);

        // Then
        assertNotNull(result);
        assertEquals(testAddressDto.getAddressId(), result.getAddressId());
        assertEquals(testAddressDto.getFullAddress(), result.getFullAddress());
        verify(addressRepository).save(any(Address.class));
    }

    @Test
    @DisplayName("Should update address")
    void testUpdate_ShouldReturnUpdatedAddress() {
        // Given
        when(addressRepository.save(any(Address.class))).thenReturn(testAddress);

        // When
        AddressDto result = addressService.update(testAddressDto);

        // Then
        assertNotNull(result);
        assertEquals(testAddressDto.getAddressId(), result.getAddressId());
        verify(addressRepository).save(any(Address.class));
    }

    @Test
    @DisplayName("Should update address by id")
    void testUpdate_WithAddressId_ShouldReturnUpdatedAddress() {
        // Given
        Integer addressId = 1;
        when(addressRepository.findById(addressId)).thenReturn(Optional.of(testAddress));
        when(addressRepository.save(any(Address.class))).thenReturn(testAddress);

        // When
        AddressDto result = addressService.update(addressId, testAddressDto);

        // Then
        assertNotNull(result);
        assertEquals(addressId, result.getAddressId());
        verify(addressRepository).findById(addressId);
        verify(addressRepository).save(any(Address.class));
    }

    @Test
    @DisplayName("Should delete address by id")
    void testDeleteById_ShouldCallRepositoryDelete() {
        // Given
        Integer addressId = 1;
        doNothing().when(addressRepository).deleteById(addressId);

        // When
        addressService.deleteById(addressId);

        // Then
        verify(addressRepository).deleteById(addressId);
    }
}

