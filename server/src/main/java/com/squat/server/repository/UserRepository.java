package com.squat.server.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import com.squat.server.model.User;

public interface UserRepository extends JpaRepository<User, Long> {
    // 로그인 시 아이디로 조회용 (SELECT * FROM user WHERE username 과 같은 의미)
    Optional<User> findByUsername(String username);
}
