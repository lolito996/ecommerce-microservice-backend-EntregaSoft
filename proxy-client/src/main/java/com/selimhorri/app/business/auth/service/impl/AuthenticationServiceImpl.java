package com.selimhorri.app.business.auth.service.impl;

import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.stereotype.Service;

import com.selimhorri.app.business.auth.model.request.AuthenticationRequest;
import com.selimhorri.app.business.auth.model.response.AuthenticationResponse;
import com.selimhorri.app.business.auth.service.AuthenticationService;
import com.selimhorri.app.exception.wrapper.IllegalAuthenticationCredentialsException;
import com.selimhorri.app.jwt.service.JwtService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
@RequiredArgsConstructor
public class AuthenticationServiceImpl implements AuthenticationService {
	
	private final AuthenticationManager authenticationManager;
	private final UserDetailsService userDetailsService;
	private final JwtService jwtService;
	
	@Override
	public AuthenticationResponse authenticate(final AuthenticationRequest authenticationRequest) {
		
		log.info("** AuthenticationResponse, authenticate user service*\n");
		
		try {
			this.authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(
					authenticationRequest.getUsername(), authenticationRequest.getPassword()));
		}
		catch (BadCredentialsException e) {
			throw new IllegalAuthenticationCredentialsException("#### Bad credentials! ####");
		}
		
		return new AuthenticationResponse(this.jwtService.generateToken(this.userDetailsService
				.loadUserByUsername(authenticationRequest.getUsername())));
	}
	
	@Override
	public Boolean authenticate(final String jwt) {
		// TODO: Implement JWT validation logic
		// For now, return false as a safe default
		// This method should validate the JWT token and return true if valid
		try {
			// Extract username from token and validate
			final String username = this.jwtService.extractUsername(jwt);
			if (username != null && !username.isEmpty()) {
				final var userDetails = this.userDetailsService.loadUserByUsername(username);
				return this.jwtService.validateToken(jwt, userDetails);
			}
			return false;
		} catch (Exception e) {
			log.warn("JWT authentication failed: {}", e.getMessage());
			return false;
		}
	}
	
	
	
}










