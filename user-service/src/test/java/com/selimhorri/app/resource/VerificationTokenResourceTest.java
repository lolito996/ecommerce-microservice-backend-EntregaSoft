package com.selimhorri.app.resource;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import java.time.LocalDate;
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
import com.selimhorri.app.dto.VerificationTokenDto;
import com.selimhorri.app.domain.RoleBasedAuthority;
import com.selimhorri.app.service.VerificationTokenService;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@WebMvcTest(VerificationTokenResource.class)
@DisplayName("VerificationTokenResource Tests")
class VerificationTokenResourceTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private VerificationTokenService verificationTokenService;

    @Autowired
    private ObjectMapper objectMapper;

    private VerificationTokenDto testVerificationTokenDto;
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

        testVerificationTokenDto = VerificationTokenDto.builder()
                .verificationTokenId(1)
                .token("test-token-123")
                .expireDate(LocalDate.now().plusDays(1))
                .credentialDto(testCredentialDto)
                .build();
    }

    @Test
    @DisplayName("Should return all verification tokens")
    void testFindAll_ShouldReturnAllVerificationTokens() throws Exception {
        // Given
        List<VerificationTokenDto> tokens = Arrays.asList(testVerificationTokenDto);
        when(verificationTokenService.findAll()).thenReturn(tokens);

        // When & Then
        mockMvc.perform(get("/api/verificationTokens"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.collection").isArray())
                .andExpect(jsonPath("$.collection[0].verificationTokenId").value(1))
                .andExpect(jsonPath("$.collection[0].token").value("test-token-123"));

        verify(verificationTokenService).findAll();
    }

    @Test
    @DisplayName("Should return verification token by id")
    void testFindById_ShouldReturnVerificationToken() throws Exception {
        // Given
        String tokenId = "1";
        when(verificationTokenService.findById(1)).thenReturn(testVerificationTokenDto);

        // When & Then
        mockMvc.perform(get("/api/verificationTokens/{verificationTokenId}", tokenId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.verificationTokenId").value(1))
                .andExpect(jsonPath("$.token").value("test-token-123"));

        verify(verificationTokenService).findById(1);
    }

    @Test
    @DisplayName("Should save verification token")
    void testSave_ShouldCreateVerificationToken() throws Exception {
        // Given
        when(verificationTokenService.save(any(VerificationTokenDto.class))).thenReturn(testVerificationTokenDto);

        // When & Then
        mockMvc.perform(post("/api/verificationTokens")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(testVerificationTokenDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.verificationTokenId").value(1))
                .andExpect(jsonPath("$.token").value("test-token-123"));

        verify(verificationTokenService).save(any(VerificationTokenDto.class));
    }

    @Test
    @DisplayName("Should update verification token")
    void testUpdate_ShouldUpdateVerificationToken() throws Exception {
        // Given
        when(verificationTokenService.update(any(VerificationTokenDto.class))).thenReturn(testVerificationTokenDto);

        // When & Then
        mockMvc.perform(put("/api/verificationTokens")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(testVerificationTokenDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.verificationTokenId").value(1));

        verify(verificationTokenService).update(any(VerificationTokenDto.class));
    }

    @Test
    @DisplayName("Should update verification token by id")
    void testUpdate_WithTokenId_ShouldUpdateVerificationToken() throws Exception {
        // Given
        String tokenId = "1";
        when(verificationTokenService.update(eq(1), any(VerificationTokenDto.class))).thenReturn(testVerificationTokenDto);

        // When & Then
        mockMvc.perform(put("/api/verificationTokens/{verificationTokenId}", tokenId)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(testVerificationTokenDto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.verificationTokenId").value(1));

        verify(verificationTokenService).update(eq(1), any(VerificationTokenDto.class));
    }

    @Test
    @DisplayName("Should delete verification token by id")
    void testDeleteById_ShouldDeleteVerificationToken() throws Exception {
        // Given
        String tokenId = "1";
        doNothing().when(verificationTokenService).deleteById(1);

        // When & Then
        mockMvc.perform(delete("/api/verificationTokens/{verificationTokenId}", tokenId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").value(true));

        verify(verificationTokenService).deleteById(1);
    }
}

