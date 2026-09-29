package com.squat.server.repository;

import com.squat.server.model.RevokedToken;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RevokedTokenRepository extends JpaRepository<RevokedToken, Long> {

    boolean existsByJti(String jti);
}