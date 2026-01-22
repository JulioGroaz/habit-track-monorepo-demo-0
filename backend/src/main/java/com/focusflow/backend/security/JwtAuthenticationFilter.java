package com.focusflow.backend.security;

import com.focusflow.backend.entity.User;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.UUID;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Responsibility: Extracts JWTs from requests and populates the security context. Architecture:
 * Security filter placed before username/password auth in the filter chain. Why: Ensures stateless
 * authentication so services can rely on SecurityContext for user IDs.
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

  private final JwtService jwtService;
  private final UserDetailsServiceImpl userDetailsService;

  public JwtAuthenticationFilter(JwtService jwtService, UserDetailsServiceImpl userDetailsService) {
    this.jwtService = jwtService;
    this.userDetailsService = userDetailsService;
  }

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws ServletException, IOException {
    String authHeader = request.getHeader("Authorization");
    if (authHeader == null || !authHeader.startsWith("Bearer ")) {
      filterChain.doFilter(request, response);
      return;
    }

    String token = authHeader.substring(7);
    UUID userId;
    try {
      userId = jwtService.extractUserId(token);
    } catch (Exception ex) {
      filterChain.doFilter(request, response);
      return;
    }

    if (userId != null && SecurityContextHolder.getContext().getAuthentication() == null) {
      try {
        User user = userDetailsService.loadUserById(userId);
        if (jwtService.isTokenValid(token, user)) {
          UsernamePasswordAuthenticationToken authToken =
              new UsernamePasswordAuthenticationToken(user, null, user.getAuthorities());
          authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
          SecurityContextHolder.getContext().setAuthentication(authToken);
        }
      } catch (Exception ex) {
        // Treat lookup or validation errors as unauthenticated and continue the chain.
      }
    }

    filterChain.doFilter(request, response);
  }
}
