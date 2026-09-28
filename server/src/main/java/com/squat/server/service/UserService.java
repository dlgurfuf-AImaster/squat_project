package com.squat.server.service;

import com.squat.server.dto.LoginRequest;
import com.squat.server.dto.LoginResponse;
import com.squat.server.dto.SignupRequest;
import com.squat.server.jwt.JwtProvider;
import com.squat.server.model.User;
import com.squat.server.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtProvider jwtProvider;

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtProvider jwtProvider) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtProvider = jwtProvider;
    }

    // 회원가입 서비스
    public String signup(SignupRequest request) {
        // 아이디 중복 검사
        Optional<User> existingUser = userRepository.findByUsername(request.getUsername());
        if (existingUser.isPresent()) {
            throw new IllegalArgumentException("이미 존재하는 아이디입니다.");
        }

        // DTO를 이용해서 받은 정보 새 객체로
        User user = new User();
        user.setUsername(request.getUsername());
        user.setName(request.getName());

        // 비밀번호 암호화
        String encodedPassword = passwordEncoder.encode(request.getPassword());
        user.setPassword(encodedPassword);

        // DB에 저장
        userRepository.save(user);
        return "회원가입 성공";
    }

    // 로그인 서비스
    public LoginResponse login(LoginRequest request) {
        String loginFailMessage = "아이디 또는 비밀번호가 일치하지 않습니다.";

        // 아이디로 유저 찾기
        User user = userRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new IllegalArgumentException(loginFailMessage));
        // 비밀번호 대조
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new IllegalArgumentException(loginFailMessage);
        }

        String token = jwtProvider.createToken(user.getUsername());

        // 성공 시 유저 정보 반환
        return new LoginResponse(token, user.getName());
    }

    // 닉네임(프로필 이름) 변경 서비스
    @Transactional
    public void updateNickname(String username, String newName) {
        // 1. 입력값 유효성 검사
        if (newName == null || newName.trim().isEmpty()) {
            throw new IllegalArgumentException("올바른 닉네임을 입력해주세요.");
        }

        // 2. 현재 사용자 DB 조회
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다."));

        // 3. 닉네임 수정 (@Transactional에 의해 메서드 종료 시 DB에 자동 UPDATE)
        user.setName(newName.trim());
    }
}
