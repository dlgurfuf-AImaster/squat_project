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

    public SquatWorkoutService(SquatWorkoutRepository squatWorkoutRepository, UserRepository userRepository) {
        this.squatWorkoutRepository = squatWorkoutRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public SquatWorkout saveWorkout(String username, SquatWorkoutRequest request) {
        // JWT 인증 정보로 전달받은 username으로 유저 조회
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다: " + username));

        SquatWorkout workout = new SquatWorkout();
        workout.setUser(user);
        workout.setSuccessCount(request.getSuccessCount());
        workout.setWaistErrorCount(request.getWaistErrorCount());
        workout.setDepthErrorCount(request.getDepthErrorCount());
        workout.setGoodMorningCount(request.getGoodMorningCount());

        return squatWorkoutRepository.save(workout);
    }
}