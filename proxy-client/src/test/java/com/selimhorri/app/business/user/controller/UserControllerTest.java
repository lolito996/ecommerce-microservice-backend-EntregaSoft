package com.selimhorri.app.business.user.controller;

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

import com.selimhorri.app.business.user.model.UserDto;
import com.selimhorri.app.business.user.model.response.UserUserServiceCollectionDtoResponse;
import com.selimhorri.app.business.user.service.UserClientService;

@ExtendWith(MockitoExtension.class)
@DisplayName("UserController Tests")
class UserControllerTest {

    @Mock
    private UserClientService userClientService;

    @InjectMocks
    private UserController userController;

    private UserDto userDto;
    private UserUserServiceCollectionDtoResponse collectionResponse;

    @BeforeEach
    void setUp() {
        userDto = new UserDto();
        userDto.setUserId(1);
        userDto.setFirstName("John");
        userDto.setLastName("Doe");
        userDto.setEmail("john.doe@example.com");

        collectionResponse = new UserUserServiceCollectionDtoResponse();
    }

    @Test
    @DisplayName("Should find all users")
    void testFindAll_ShouldReturnUsers() {
        // Given
        ResponseEntity<UserUserServiceCollectionDtoResponse> serviceResponse = 
                ResponseEntity.ok(collectionResponse);
        when(userClientService.findAll()).thenReturn(serviceResponse);

        // When
        ResponseEntity<UserUserServiceCollectionDtoResponse> response = userController.findAll();

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(userClientService).findAll();
    }

    @Test
    @DisplayName("Should find user by id")
    void testFindById_ShouldReturnUser() {
        // Given
        String userId = "1";
        ResponseEntity<UserDto> serviceResponse = ResponseEntity.ok(userDto);
        when(userClientService.findById(userId)).thenReturn(serviceResponse);

        // When
        ResponseEntity<UserDto> response = userController.findById(userId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        verify(userClientService).findById(userId);
    }

    @Test
    @DisplayName("Should find user by username")
    void testFindByUsername_ShouldReturnUser() {
        // Given
        String username = "johndoe";
        ResponseEntity<UserDto> serviceResponse = ResponseEntity.ok(userDto);
        when(userClientService.findByUsername(username)).thenReturn(serviceResponse);

        // When
        ResponseEntity<UserDto> response = userController.findByUsername(username);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(userClientService).findByUsername(username);
    }

    @Test
    @DisplayName("Should save user")
    void testSave_ShouldReturnSavedUser() {
        // Given
        ResponseEntity<UserDto> serviceResponse = ResponseEntity.ok(userDto);
        when(userClientService.save(userDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<UserDto> response = userController.save(userDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(userClientService).save(userDto);
    }

    @Test
    @DisplayName("Should update user")
    void testUpdate_ShouldReturnUpdatedUser() {
        // Given
        ResponseEntity<UserDto> serviceResponse = ResponseEntity.ok(userDto);
        when(userClientService.update(userDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<UserDto> response = userController.update(userDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(userClientService).update(userDto);
    }

    @Test
    @DisplayName("Should delete user by id")
    void testDeleteById_ShouldReturnTrue() {
        // Given
        String userId = "1";
        ResponseEntity<Boolean> serviceResponse = ResponseEntity.ok(true);
        when(userClientService.deleteById(userId)).thenReturn(serviceResponse);

        // When
        ResponseEntity<Boolean> response = userController.deleteById(userId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody());
        verify(userClientService).deleteById(userId);
    }
}

