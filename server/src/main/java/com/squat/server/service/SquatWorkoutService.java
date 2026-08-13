package com.squat.server.service;

import com.squat.server.dto.SquatWorkoutRequest;
import com.squat.server.dto.SquatWorkoutResponse;
import com.squat.server.model.SquatWorkout;
import com.squat.server.model.User;
import com.squat.server.repository.SquatWorkoutRepository;
import com.squat.server.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class SquatWorkoutService {

    private final SquatWorkoutRepository squatWorkoutRepository;
    private final UserRepository userRepository;

    public SquatWorkoutService(SquatWorkoutRepository squatWorkoutRepository,
                               UserRepository userRepository) {
        this.squatWorkoutRepository = squatWorkoutRepository;
        this.userRepository = userRepository;
    }

    // 스쿼트 기록 저장 메소드
    @Transactional
    public SquatWorkout saveWorkout(String username, SquatWorkoutRequest request) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다: " + username));

        // SquatWorkout 엔티티 생성 및 pure 데이터 세팅
        SquatWorkout workout = new SquatWorkout();
        workout.setUuid(request.getUuid());
        workout.setUser(user);
        workout.setSuccessCount(request.getSuccessCount());
        workout.setWaistErrorCount(request.getWaistErrorCount());
        workout.setDepthErrorCount(request.getDepthErrorCount());
        workout.setGoodMorningCount(request.getGoodMorningCount());
        workout.setRecordTime(request.getRecordTime());

        return squatWorkoutRepository.save(workout);
    }

    // 로그인한 사용자의 서버 저장 운동 기록 전체 조회 메서드
    @Transactional(readOnly = true)
    public List<SquatWorkoutResponse> getRecordsByUsername(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다: " + username));

        return squatWorkoutRepository.findByUserOrderByIdDesc(user)
                .stream()
                .map(SquatWorkoutResponse::from)
                .collect(Collectors.toList());
    }

    // 서버 기록 삭제 메소드 (UUID 기준 삭제)
    @Transactional
    public void deleteRecordByUuid(String username, String uuid) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다: " + username));

        squatWorkoutRepository.deleteByUserAndUuid(user, uuid);
    }
}