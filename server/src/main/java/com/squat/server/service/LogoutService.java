package com.squat.server.service;

import com.squat.server.jwt.JwtProvider;
import com.squat.server.model.RevokedToken;
import com.squat.server.repository.RevokedTokenRepository;
import org.springframework.stereotype.Service;

import java.util.Date;

@Service
public class LogoutService {

    private final JwtProvider jwtProvider;
    private final RevokedTokenRepository revokedTokenRepository;

    public LogoutService(
            JwtProvider jwtProvider,
            RevokedTokenRepository revokedTokenRepository) {

        this.jwtProvider = jwtProvider;
        this.revokedTokenRepository = revokedTokenRepository;
    }

    // JWT를 폐기 처리
    public void logout(String token) {

        // JWT에서 고유 ID 추출
        String jti = jwtProvider.getJti(token);

        // JWT의 원래 만료시간 추출
        Date expiresAt = jwtProvider.getExpiration(token);

        // 폐기된 토큰 객체 생성
        RevokedToken revokedToken = new RevokedToken();

        revokedToken.setJti(jti);
        revokedToken.setExpiresAt(expiresAt);

        // DB에 저장
        revokedTokenRepository.save(revokedToken);
    }
}