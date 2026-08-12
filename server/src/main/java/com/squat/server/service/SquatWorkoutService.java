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

    // 💡 GeminiService 주입 제거
    public SquatWorkoutService(SquatWorkoutRepository squatWorkoutRepository,
                               UserRepository userRepository) {
        this.squatWorkoutRepository = squatWorkoutRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public SquatWorkout saveWorkout(String username, SquatWorkoutRequest request) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다: " + username));

        // SquatWorkout 엔티티 생성 및 pure 데이터 세팅 (Gemini 호출 제거)
        SquatWorkout workout = new SquatWorkout();
        workout.setUser(user);
        workout.setSuccessCount(request.getSuccessCount());
        workout.setWaistErrorCount(request.getWaistErrorCount());
        workout.setDepthErrorCount(request.getDepthErrorCount());
        workout.setGoodMorningCount(request.getGoodMorningCount());
        workout.setRecordTime(request.getRecordTime());
        // coachingMessage는 저장 시점에 생성하지 않고 null로 둠
        // (이후 사용자가 AI 코칭을 요청할 때 SquatCoachingService에서 생성/반환)

        return squatWorkoutRepository.save(workout);
    }
}