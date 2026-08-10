package com.squat.server.controller;

import com.squat.server.dto.SquatWorkoutRequest;
import com.squat.server.dto.SquatWorkoutResponse;
import com.squat.server.model.SquatWorkout;
import com.squat.server.service.SquatWorkoutService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/squat")
public class SquatWorkoutController {

    private final SquatWorkoutService squatWorkoutService;

    public SquatWorkoutController(SquatWorkoutService squatWorkoutService) {
        this.squatWorkoutService = squatWorkoutService;
    }

    @PostMapping("/record")
    public ResponseEntity<SquatWorkoutResponse> saveRecord(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody SquatWorkoutRequest request
    ) {
        // 1. 운동 기록 저장 및 Gemini AI 코칭 메시지 생성
        SquatWorkout savedWorkout = squatWorkoutService.saveWorkout(userDetails.getUsername(), request);

        // 2. 엔티티를 응답 DTO로 변환하여 AI 메시지와 함께 클라이언트(Flutter)로 전달
        return ResponseEntity.ok(SquatWorkoutResponse.from(savedWorkout));
    }
}