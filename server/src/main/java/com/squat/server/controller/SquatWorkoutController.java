package com.squat.server.controller;

import com.squat.server.dto.AggregateCoachingRequest;
import com.squat.server.dto.CoachingResponse;
import com.squat.server.dto.SquatWorkoutRequest;
import com.squat.server.dto.SquatWorkoutResponse;
import com.squat.server.model.SquatWorkout;
import com.squat.server.service.SquatCoachingService;
import com.squat.server.service.SquatWorkoutService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/squat")
public class SquatWorkoutController {

    private final SquatWorkoutService squatWorkoutService;
    private final SquatCoachingService squatCoachingService;

    public SquatWorkoutController(SquatWorkoutService squatWorkoutService,
                                  SquatCoachingService squatCoachingService) {
        this.squatWorkoutService = squatWorkoutService;
        this.squatCoachingService = squatCoachingService;
    }

    // 1. 단순 스쿼트 운동 기록 저장 (AI 미호출, 빠른 저장)
    @PostMapping("/record")
    public ResponseEntity<SquatWorkoutResponse> saveRecord(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody SquatWorkoutRequest request
    ) {
        SquatWorkout savedWorkout = squatWorkoutService.saveWorkout(userDetails.getUsername(), request);
        return ResponseEntity.ok(SquatWorkoutResponse.from(savedWorkout));
    }

    // 2. 단일 운동 기록 ID 기반 AI 코칭 요청
    @PostMapping("/coaching/single/{workoutId}")
    public ResponseEntity<CoachingResponse> getSingleCoaching(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long workoutId
    ) {
        CoachingResponse response = squatCoachingService.getSingleCoaching(userDetails.getUsername(), workoutId);
        return ResponseEntity.ok(response);
    }

    // 3. 장기 / 다중 운동 기록 집계 AI 코칭 요청 (기본값: 최근 30일)
    @PostMapping("/coaching/aggregate")
    public ResponseEntity<CoachingResponse> getAggregateCoaching(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody(required = false) AggregateCoachingRequest request
    ) {
        if (request == null) {
            request = new AggregateCoachingRequest();
        }
        CoachingResponse response = squatCoachingService.getAggregateCoaching(userDetails.getUsername(), request);
        return ResponseEntity.ok(response);
    }
}