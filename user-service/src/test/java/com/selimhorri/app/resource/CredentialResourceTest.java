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
import com.selimhorri.app.dto.CredentialDto;
import com.selimhorri.app.domain.RoleBasedAuthority;
import com.selimhorri.app.service.CredentialService;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@WebMvcTest(CredentialResource.class)
@DisplayName("CredentialResource Tests")
class CredentialResourceTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private CredentialService credentialService;

    @Autowired
    private ObjectMapper objectMapper;

    private CredentialDto testCredentialDto;

    @BeforeEach
    void setUp() {
        testCredentialDto = CredentialDto.builder()
                .credentialId(1)
                .username("testuser")
                .password("password123")
                .roleBasedAuthority(RoleBasedAuthority.ROLE_USER)
                .isEnabled(true)
                .isAccountNonExpired(true)
                .isAccountNonLocked(true)
                .isCredentialsNonExpired(true)
                .build();
    }

    @Test
    @DisplayName("Should return all credentials")
    void testFindAll_ShouldReturnAllCredentials() throws Exception {
        // Given
        List<CredentialDto> credentials = Arrays.asList(testCredentialDto);
        when(credentialService.findAll()).thenReturn(credentials);

        // When & Then
        mockMvc.perform(get("/api/credentials"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.collection").isArray())
                .andExpect(jsonPath("$.collection[0].credentialId").value(1))
                .andExpect(jsonPath("$.collection[0].username").value("testuser"));

        verify(credentialService).findAll();
    }

    @Test
    @DisplayName("Should return credential by id")
    void testFindById_ShouldReturnCredential() throws Exception {
        // Given
        String credentialId = "1";
        when(credentialService.findById(1)).thenReturn(testCredentialDto);

        // When & Then
        mockMvc.perform(get("/api/credentials/{credentialId}", credentialId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.credentialId").value(1))
                .andExpect(jsonPath("$.username").value("testuser"));

        verify(credentialService).findById(1);
    }

    @Test
    @DisplayName("Should return credential by username")
    void testFindByUsername_ShouldReturnCredential() throws Exception {
        // Given
        String username = "testuser";
        when(credentialService.findByUsername(username)).thenReturn(testCredentialDto);

        // When & Then
        mockMvc.perform(get("/api/credentials/username/{username}", username))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.credentialId").value(1))
                .andExpect(jsonPath("$.username").value("testuser"));

        verify(credentialService).findByUsername(username);
    }

    @Test
    @DisplayName("Should save credential")
    void testSave_ShouldCreateCredential() throws Exception {
        // Given
        when(credentialService.save(any(CredentialDto.class))).thenReturn(testCredentialDto);

        // When & Then
        mockMvc.perform(post("/api/credentials")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(testCredentialDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.credentialId").value(1))
                .andExpect(jsonPath("$.username").value("testuser"));

        verify(credentialService).save(any(CredentialDto.class));
    }

    @Test
    @DisplayName("Should update credential")
    void testUpdate_ShouldUpdateCredential() throws Exception {
        // Given
        when(credentialService.update(any(CredentialDto.class))).thenReturn(testCredentialDto);

        // When & Then
        mockMvc.perform(put("/api/credentials")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(testCredentialDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.credentialId").value(1));

        verify(credentialService).update(any(CredentialDto.class));
    }

    @Test
    @DisplayName("Should update credential by id")
    void testUpdate_WithCredentialId_ShouldUpdateCredential() throws Exception {
        // Given
        String credentialId = "1";
        when(credentialService.update(eq(1), any(CredentialDto.class))).thenReturn(testCredentialDto);

        // When & Then
        mockMvc.perform(put("/api/credentials/{credentialId}", credentialId)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(testCredentialDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.credentialId").value(1));

        verify(credentialService).update(eq(1), any(CredentialDto.class));
    }

    @Test
    @DisplayName("Should delete credential by id")
    void testDeleteById_ShouldDeleteCredential() throws Exception {
        // Given
        String credentialId = "1";
        doNothing().when(credentialService).deleteById(1);

        // When & Then
        mockMvc.perform(delete("/api/credentials/{credentialId}", credentialId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").value(true));

        verify(credentialService).deleteById(1);
    }
}

