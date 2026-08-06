package com.squat.server.controller;

import com.squat.server.dto.SquatWorkoutRequest;
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
    public ResponseEntity<String> saveRecord(
            @AuthenticationPrincipal UserDetails userDetails, // 표준 형태
            @RequestBody SquatWorkoutRequest request
    ) {
        SquatWorkout savedWorkout = squatWorkoutService.saveWorkout(userDetails.getUsername(), request);
        return ResponseEntity.ok("스쿼트 운동 기록이 정상적으로 저장되었습니다. (ID: " + savedWorkout.getId() + ")");
    }
}