package com.squat.server.service;

import com.squat.server.dto.AggregateCoachingRequest;
import com.squat.server.dto.CoachingResponse;
import com.squat.server.model.SquatWorkout;
import com.squat.server.model.User;
import com.squat.server.repository.SquatWorkoutRepository;
import com.squat.server.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

/// 단일, 장기 코칭 서비스 구현 파트
@Service
public class SquatCoachingService {

    private final SquatWorkoutRepository squatWorkoutRepository;
    private final UserRepository userRepository;
    private final GeminiService geminiService;

    public SquatCoachingService(SquatWorkoutRepository squatWorkoutRepository,
                                UserRepository userRepository,
                                GeminiService geminiService) {
        this.squatWorkoutRepository = squatWorkoutRepository;
        this.userRepository = userRepository;
        this.geminiService = geminiService;
    }

    // 1. 단일 기록 코칭
    @Transactional(readOnly = true)
    public CoachingResponse getSingleCoaching(String username, Long workoutId) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다."));

        SquatWorkout workout = squatWorkoutRepository.findById(workoutId)
                .orElseThrow(() -> new IllegalArgumentException("기록을 찾을 수 없습니다: " + workoutId));

        String coachingMessage = geminiService.generateSingleCoaching(
                workout.getSuccessCount(),
                workout.getWaistErrorCount(),
                workout.getDepthErrorCount(),
                workout.getGoodMorningCount()
        );

        return new CoachingResponse("SINGLE", 1,
                workout.getSuccessCount(),
                workout.getWaistErrorCount(),
                workout.getDepthErrorCount(),
                workout.getGoodMorningCount(),
                coachingMessage);
    }

    // 2. 장기 / 다중 선택 코칭 (명시적 3가지 선택지 검증)
    @Transactional(readOnly = true)
    public CoachingResponse getAggregateCoaching(String username, AggregateCoachingRequest request) {
        if (request == null) {
            throw new IllegalArgumentException("요청 본문(Body)이 비어있습니다. 분석 조건을 선택해 주세요.");
        }

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다."));

        List<SquatWorkout> workouts;

        // 선택지 1: 개별 ID 목록 선택
        if (request.getWorkoutIds() != null && !request.getWorkoutIds().isEmpty()) {
            workouts = squatWorkoutRepository.findByUserAndIdIn(user, request.getWorkoutIds());
        }
        // 선택지 2: 날짜 범위 직접 지정
        else if (request.getStartDate() != null && request.getEndDate() != null) {
            LocalDateTime start = request.getStartDate().atStartOfDay();
            LocalDateTime end = request.getEndDate().atTime(LocalTime.MAX);
            workouts = squatWorkoutRepository.findByUserAndRecordTimeBetween(user, start, end);
        }
        // 선택지 3: '최근 30일 코칭' 명시적 버튼 선택 (recent30Days == true)
        else if (Boolean.TRUE.equals(request.getRecent30Days())) {
            LocalDateTime start = LocalDateTime.now().minusDays(30);
            LocalDateTime end = LocalDateTime.now();
            workouts = squatWorkoutRepository.findByUserAndRecordTimeBetween(user, start, end);
        }
        // 조건이 하나도 해당하지 않는 경우 오류 처리 (암묵적 기본값 없음)
        else {
            throw new IllegalArgumentException("분석 조건을 선택해야 합니다. (개별 기록 선택, 날짜 범위 지정, 최근 30일 분석 중 하나 필수)");
        }

        if (workouts.isEmpty()) {
            return new CoachingResponse("AGGREGATE", 0, 0, 0, 0, 0, "선택하신 조건에 해당하는 운동 기록이 없습니다.");
        }

        // 수치 합산
        int totalSuccess = workouts.stream().mapToInt(SquatWorkout::getSuccessCount).sum();
        int totalWaist = workouts.stream().mapToInt(SquatWorkout::getWaistErrorCount).sum();
        int totalDepth = workouts.stream().mapToInt(SquatWorkout::getDepthErrorCount).sum();
        int totalGoodMorning = workouts.stream().mapToInt(SquatWorkout::getGoodMorningCount).sum();

        String coachingMessage = geminiService.generateAggregateCoaching(
                workouts.size(), totalSuccess, totalWaist, totalDepth, totalGoodMorning
        );

        return new CoachingResponse("AGGREGATE", workouts.size(),
                totalSuccess, totalWaist, totalDepth, totalGoodMorning, coachingMessage);
    }
}