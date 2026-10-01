package com.squat.server.jwt;

import com.squat.server.repository.RevokedTokenRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.jspecify.annotations.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class JwtFilter extends OncePerRequestFilter {

    private final JwtProvider jwtProvider;
    private final RevokedTokenRepository revokedTokenRepository;

    public JwtFilter(
            JwtProvider jwtProvider,
            RevokedTokenRepository revokedTokenRepository) {

        this.jwtProvider = jwtProvider;
        this.revokedTokenRepository = revokedTokenRepository;
    }

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain)
            throws ServletException, IOException {

        // Authorization 헤더에서 토큰 추출
        String token = resolveToken(request);

        // 토큰 유효성 검증
        if (StringUtils.hasText(token) && jwtProvider.validateToken(token)) {

            // JWT의 고유 ID(jti) 추출
            String jti = jwtProvider.getJti(token);

            // 로그아웃된 토큰인지 확인
            boolean revoked = revokedTokenRepository.existsByJti(jti);

            // 폐기되지 않은 토큰만 인증 처리
            if (!revoked) {

                String username = jwtProvider.getUsername(token);

                // Spring Security 표준 UserDetails 객체 생성
                UserDetails userDetails = User.builder()
                        .username(username)
                        .password("")
                        .roles("USER")
                        .build();

                // 인증 완료 객체 생성
                UsernamePasswordAuthenticationToken authentication =
                        new UsernamePasswordAuthenticationToken(
                                userDetails,
                                null,
                                userDetails.getAuthorities()
                        );

                // SecurityContext 등록
                SecurityContextHolder.getContext()
                        .setAuthentication(authentication);
            }
        }

        filterChain.doFilter(request, response);
    }

    // Authorization 헤더에서 Bearer 토큰 파싱
    private String resolveToken(HttpServletRequest request) {

        String bearerToken = request.getHeader("Authorization");

        if (StringUtils.hasText(bearerToken)
                && bearerToken.startsWith("Bearer ")) {

            return bearerToken.substring(7);
        }

        return null;
    }
}