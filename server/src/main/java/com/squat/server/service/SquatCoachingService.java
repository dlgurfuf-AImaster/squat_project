package com.squat.server.service;

import com.squat.server.dto.AggregateCoachingRequest;
import com.squat.server.dto.CoachingResponse;
import com.squat.server.model.SquatWorkout;
import com.squat.server.model.User;
import com.squat.server.repository.SquatWorkoutRepository;
import com.squat.server.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
    @Transactional
    public CoachingResponse getSingleCoaching(String username, String uuid) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다."));

        SquatWorkout workout = squatWorkoutRepository.findByUserAndUuid(user, uuid)
                .orElseThrow(() -> new IllegalArgumentException("기록을 찾을 수 없습니다: " + uuid));

        // DB에 이미 저장된 코칭 메시지가 있다면 즉시 반환
        if (workout.getCoachingMessage() != null && !workout.getCoachingMessage().isBlank()) {
            return new CoachingResponse("SINGLE", 1,
                    workout.getSuccessCount(),
                    workout.getWaistErrorCount(),
                    workout.getDepthErrorCount(),
                    workout.getFastRepCount(),
                    workout.getCoachingMessage());
        }

        // Gemini AI 호출
        String coachingMessage = geminiService.generateSingleCoaching(
                workout.getSuccessCount(),
                workout.getWaistErrorCount(),
                workout.getDepthErrorCount(),
                workout.getFastRepCount()
        );

        // Gemini API 실패 시 DB 업데이트를 스킵하고 null 반환
        if (coachingMessage == null) {
            return null;
        }

        // 성공했을 때만 DB에 저장
        workout.setCoachingMessage(coachingMessage);

        return new CoachingResponse("SINGLE", 1,
                workout.getSuccessCount(),
                workout.getWaistErrorCount(),
                workout.getDepthErrorCount(),
                workout.getFastRepCount(),
                coachingMessage);
    }

    // 2. 장기 / 다중 선택 코칭
    @Transactional(readOnly = true)
    public CoachingResponse getAggregateCoaching(
            String username,
            AggregateCoachingRequest request
    ) {
        if (request == null) {
            throw new IllegalArgumentException(
                    "요청 본문(Body)이 비어있습니다. 분석할 기록을 선택해 주세요."
            );
        }

        if (request.getWorkoutUuids() == null ||
                request.getWorkoutUuids().isEmpty()) {
            throw new IllegalArgumentException(
                    "분석할 운동 기록을 선택해야 합니다."
            );
        }

        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다."));

        List<SquatWorkout> workouts =
                squatWorkoutRepository.findByUserAndUuidIn(
                        user,
                        request.getWorkoutUuids()
                );

        if (workouts.isEmpty()) {
            return new CoachingResponse("AGGREGATE", 0, 0, 0, 0, 0, "선택하신 조건에 해당하는 운동 기록이 없습니다.");
        }

        // 수치 합산
        int totalCount = workouts.stream().mapToInt(SquatWorkout::getTotalCount).sum();
        int totalSuccess = workouts.stream().mapToInt(SquatWorkout::getSuccessCount).sum();
        int totalWaist = workouts.stream().mapToInt(SquatWorkout::getWaistErrorCount).sum();
        int totalDepth = workouts.stream().mapToInt(SquatWorkout::getDepthErrorCount).sum();
        int totalFastRepCount = workouts.stream().mapToInt(SquatWorkout::getFastRepCount).sum();

        String coachingMessage = geminiService.generateAggregateCoaching(
                workouts.size(),
                totalCount,
                totalSuccess,
                totalWaist,
                totalDepth,
                totalFastRepCount
        );

        return new CoachingResponse(
                "AGGREGATE",
                workouts.size(),
                totalSuccess,
                totalWaist,
                totalDepth,
                totalFastRepCount,
                coachingMessage
        );
    }
}