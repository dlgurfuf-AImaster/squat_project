package com.squat.server.controller;

import com.squat.server.dto.LoginRequest;
import com.squat.server.dto.LoginResponse;
import com.squat.server.dto.SignupRequest;
import com.squat.server.dto.UpdateProfileRequest;
import com.squat.server.service.LogoutService;
import com.squat.server.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

/// 로그인용 유저 컨트롤러
@RestController
@RequestMapping("/api/v1/user")
public class UserController {

    private final UserService userService;
    private final LogoutService logoutService;

    public UserController(
            UserService userService,
            LogoutService logoutService) {

        this.userService = userService;
        this.logoutService = logoutService;
    }
    // 회원가입 API
    @PostMapping("/signup")
    public ResponseEntity<String> signup(@RequestBody SignupRequest request) {
        try {
            String result = userService.signup(request);
            return ResponseEntity.ok(result);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // 로그인 API
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        try {
            LoginResponse response = userService.login(request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // 프로필(닉네임) 수정 API 추가
    @PutMapping("/profile")
    public ResponseEntity<String> updateProfile(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody UpdateProfileRequest request
    ) {
        try {
            // userDetails.getUsername()으로 현재 요청을 보낸 유저 ID/식별값 전달
            userService.updateNickname(userDetails.getUsername(), request.getName());
            return ResponseEntity.ok("닉네임이 성공적으로 변경되었습니다.");
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // 현재 로그인한 사용자 정보 조회 (자동 로그인용)
    @GetMapping("/me")
    public ResponseEntity<?> getMyProfile(
            @AuthenticationPrincipal UserDetails userDetails
    ) {
        try {
            return ResponseEntity.ok(
                    userService.getMyProfile(userDetails.getUsername())
            );
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // 로그아웃 API
    @PostMapping("/logout")
    public ResponseEntity<?> logout(
            @RequestHeader("Authorization") String authorization) {

        if (!authorization.startsWith("Bearer ")) {
            return ResponseEntity.badRequest().body("잘못된 토큰입니다.");
        }

        String token = authorization.substring(7);

        logoutService.logout(token);

        return ResponseEntity.ok("로그아웃 성공");
    }
}