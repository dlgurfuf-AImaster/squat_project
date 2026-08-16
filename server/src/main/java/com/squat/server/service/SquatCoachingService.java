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

    // 1. 단일 기록 코칭 (UUID 기준 및 DB 자동 저장/재활용 적용)
    @Transactional
    public CoachingResponse getSingleCoaching(String username, String uuid) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다."));

        SquatWorkout workout = squatWorkoutRepository.findByUserAndUuid(user, uuid)
                .orElseThrow(() -> new IllegalArgumentException("기록을 찾을 수 없습니다: " + uuid));

        // DB에 이미 저장된 성공 코칭 메시지가 있다면 즉시 반환
        if (workout.getCoachingMessage() != null && !workout.getCoachingMessage().isBlank()) {
            return new CoachingResponse("SINGLE", 1,
                    workout.getSuccessCount(),
                    workout.getWaistErrorCount(),
                    workout.getDepthErrorCount(),
                    workout.getGoodMorningCount(),
                    workout.getCoachingMessage());
        }

        // Gemini AI 호출
        String coachingMessage = geminiService.generateSingleCoaching(
                workout.getSuccessCount(),
                workout.getWaistErrorCount(),
                workout.getDepthErrorCount(),
                workout.getGoodMorningCount()
        );

        // Gemini API 실패로 null이 들어오면 DB 업데이트를 스킵하고 null 반환
        if (coachingMessage == null) {
            return null;
        }

        // 성공했을 때만 DB에 저장 (더티 체킹)
        workout.setCoachingMessage(coachingMessage);

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

        // 선택지 1: 개별 UUID 목록 선택
        if (request.getWorkoutUuids() != null && !request.getWorkoutUuids().isEmpty()) {
            workouts = squatWorkoutRepository.findByUserAndUuidIn(user, request.getWorkoutUuids());
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