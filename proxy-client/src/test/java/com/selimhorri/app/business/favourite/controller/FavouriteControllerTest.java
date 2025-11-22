package com.selimhorri.app.business.favourite.controller;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import java.time.LocalDateTime;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import com.selimhorri.app.business.favourite.model.FavouriteDto;
import com.selimhorri.app.business.favourite.model.FavouriteId;
import com.selimhorri.app.business.favourite.model.response.FavouriteFavouriteServiceCollectionDtoResponse;
import com.selimhorri.app.business.favourite.service.FavouriteClientService;

@ExtendWith(MockitoExtension.class)
@DisplayName("FavouriteController Tests")
class FavouriteControllerTest {

    @Mock
    private FavouriteClientService favouriteClientService;

    @InjectMocks
    private FavouriteController favouriteController;

    private FavouriteDto favouriteDto;
    private FavouriteId favouriteId;
    private FavouriteFavouriteServiceCollectionDtoResponse collectionResponse;

    @BeforeEach
    void setUp() {
        LocalDateTime likeDate = LocalDateTime.now();
        favouriteId = new FavouriteId(1, 1, likeDate);
        favouriteDto = new FavouriteDto();
        favouriteDto.setUserId(1);
        favouriteDto.setProductId(1);
        favouriteDto.setLikeDate(likeDate);

        collectionResponse = new FavouriteFavouriteServiceCollectionDtoResponse();
    }

    @Test
    @DisplayName("Should find all favourites")
    void testFindAll_ShouldReturnFavourites() {
        // Given
        ResponseEntity<FavouriteFavouriteServiceCollectionDtoResponse> serviceResponse = 
                ResponseEntity.ok(collectionResponse);
        when(favouriteClientService.findAll()).thenReturn(serviceResponse);

        // When
        ResponseEntity<FavouriteFavouriteServiceCollectionDtoResponse> response = favouriteController.findAll();

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(favouriteClientService).findAll();
    }

    @Test
    @DisplayName("Should find favourite by path variables")
    void testFindById_WithPathVariables_ShouldReturnFavourite() {
        // Given
        String userId = "1";
        String productId = "1";
        String likeDate = "2024-01-01T10:00:00";
        ResponseEntity<FavouriteDto> serviceResponse = ResponseEntity.ok(favouriteDto);
        when(favouriteClientService.findById(userId, productId, likeDate)).thenReturn(serviceResponse);

        // When
        ResponseEntity<FavouriteDto> response = favouriteController.findById(userId, productId, likeDate);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        verify(favouriteClientService).findById(userId, productId, likeDate);
    }

    @Test
    @DisplayName("Should find favourite by request body")
    void testFindById_WithRequestBody_ShouldReturnFavourite() {
        // Given
        ResponseEntity<FavouriteDto> serviceResponse = ResponseEntity.ok(favouriteDto);
        when(favouriteClientService.findById(favouriteId)).thenReturn(serviceResponse);

        // When
        ResponseEntity<FavouriteDto> response = favouriteController.findById(favouriteId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        verify(favouriteClientService).findById(favouriteId);
    }

    @Test
    @DisplayName("Should save favourite")
    void testSave_ShouldReturnSavedFavourite() {
        // Given
        ResponseEntity<FavouriteDto> serviceResponse = ResponseEntity.ok(favouriteDto);
        when(favouriteClientService.save(favouriteDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<FavouriteDto> response = favouriteController.save(favouriteDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(favouriteClientService).save(favouriteDto);
    }

    @Test
    @DisplayName("Should update favourite")
    void testUpdate_ShouldReturnUpdatedFavourite() {
        // Given
        ResponseEntity<FavouriteDto> serviceResponse = ResponseEntity.ok(favouriteDto);
        when(favouriteClientService.update(favouriteDto)).thenReturn(serviceResponse);

        // When
        ResponseEntity<FavouriteDto> response = favouriteController.update(favouriteDto);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        verify(favouriteClientService).update(favouriteDto);
    }

    @Test
    @DisplayName("Should delete favourite by path variables")
    void testDeleteById_WithPathVariables_ShouldReturnTrue() {
        // Given
        String userId = "1";
        String productId = "1";
        String likeDate = "2024-01-01T10:00:00";
        ResponseEntity<Boolean> serviceResponse = ResponseEntity.ok(true);
        when(favouriteClientService.deleteById(userId, productId, likeDate)).thenReturn(serviceResponse);

        // When
        ResponseEntity<Boolean> response = favouriteController.deleteById(userId, productId, likeDate);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody());
        verify(favouriteClientService).deleteById(userId, productId, likeDate);
    }

    @Test
    @DisplayName("Should delete favourite by request body")
    void testDeleteById_WithRequestBody_ShouldReturnTrue() {
        // Given
        ResponseEntity<Boolean> serviceResponse = ResponseEntity.ok(true);
        when(favouriteClientService.deleteById(favouriteId)).thenReturn(serviceResponse);

        // When
        ResponseEntity<Boolean> response = favouriteController.deleteById(favouriteId);

        // Then
        assertNotNull(response);
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertTrue(response.getBody());
        verify(favouriteClientService).deleteById(favouriteId);
    }
}

