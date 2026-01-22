package com.focusflow.backend.security;

import com.focusflow.backend.entity.User;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;
import java.util.UUID;
import java.util.function.Function;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * Responsibility: Issues and validates JWTs for stateless authentication. Architecture: Security
 * service used by auth flows and request filters. Why: Centralizes token logic to keep controllers
 * and filters focused on workflow.
 */
@Service
public class JwtService {

  @Value("${app.jwt.secret}")
  private String secret;

  @Value("${app.jwt.expiration-minutes}")
  private long expirationMinutes;

  public String generateToken(User user) {
    Instant now = Instant.now();
    return Jwts.builder()
        .setSubject(user.getEmail())
        .claim("userId", user.getId().toString())
        .setIssuedAt(Date.from(now))
        .setExpiration(Date.from(now.plus(expirationMinutes, ChronoUnit.MINUTES)))
        .signWith(getSigningKey(), SignatureAlgorithm.HS256)
        .compact();
  }

  public UUID extractUserId(String token) {
    String value = extractClaim(token, claims -> claims.get("userId", String.class));
    return value != null ? UUID.fromString(value) : null;
  }

  public String extractSubject(String token) {
    return extractClaim(token, Claims::getSubject);
  }

  public boolean isTokenValid(String token, User user) {
    UUID tokenUserId = extractUserId(token);
    return tokenUserId != null && tokenUserId.equals(user.getId()) && !isTokenExpired(token);
  }

  private boolean isTokenExpired(String token) {
    return extractClaim(token, Claims::getExpiration).before(new Date());
  }

  private <T> T extractClaim(String token, Function<Claims, T> resolver) {
    Claims claims =
        Jwts.parserBuilder().setSigningKey(getSigningKey()).build().parseClaimsJws(token).getBody();
    return resolver.apply(claims);
  }

  private Key getSigningKey() {
    // Use UTF-8 bytes of the configured secret for HMAC signing.
    byte[] keyBytes = secret.getBytes(StandardCharsets.UTF_8);
    return Keys.hmacShaKeyFor(keyBytes);
  }
}
