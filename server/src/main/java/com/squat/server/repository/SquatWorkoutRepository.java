package com.squat.server.repository;

import com.squat.server.model.SquatWorkout;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SquatWorkoutRepository extends JpaRepository<SquatWorkout, Long> {
    // 특정 유저의 최근 기록 분석용 (임시)
    List<SquatWorkout> findByUserIdOrderByEndTimeDesc(Long userId);
}
