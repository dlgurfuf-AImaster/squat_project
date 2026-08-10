package com.squat.server.service;

import com.squat.server.dto.SquatWorkoutRequest;
import com.squat.server.model.SquatWorkout;
import com.squat.server.model.User;
import com.squat.server.repository.SquatWorkoutRepository;
import com.squat.server.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SquatWorkoutService {

    private final SquatWorkoutRepository squatWorkoutRepository;
    private final UserRepository userRepository;
    private final GeminiService geminiService; // 💡 GeminiService 주입 추가

    public SquatWorkoutService(SquatWorkoutRepository squatWorkoutRepository,
                               UserRepository userRepository,
                               GeminiService geminiService) {
        this.squatWorkoutRepository = squatWorkoutRepository;
        this.userRepository = userRepository;
        this.geminiService = geminiService;
    }

    @Transactional
    public SquatWorkout saveWorkout(String username, SquatWorkoutRequest request) {
        // JWT 인증 정보로 전달받은 username으로 유저 조회
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다: " + username));

        // 1. Gemini AI를 호출하여 스쿼트 코칭 메시지 생성
        String coachingMessage = geminiService.generateCoachingMessage(
                request.getSuccessCount(),
                request.getWaistErrorCount(),
                request.getDepthErrorCount(),
                request.getGoodMorningCount()
        );

        // 2. SquatWorkout 엔티티 생성 및 데이터 세팅
        SquatWorkout workout = new SquatWorkout();
        workout.setUser(user);
        workout.setSuccessCount(request.getSuccessCount());
        workout.setWaistErrorCount(request.getWaistErrorCount());
        workout.setDepthErrorCount(request.getDepthErrorCount());
        workout.setGoodMorningCount(request.getGoodMorningCount());
        workout.setCoachingMessage(coachingMessage); // 💡 AI 코칭 메시지 세팅

        // 3. DB 저장 (@PrePersist로 totalCount, endTime 자동 설정됨)
        return squatWorkoutRepository.save(workout);
    }
}