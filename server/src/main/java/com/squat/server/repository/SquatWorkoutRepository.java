package com.squat.server.repository;

import com.squat.server.model.SquatWorkout;
import com.squat.server.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface SquatWorkoutRepository extends JpaRepository<SquatWorkout, Long> {
    List<SquatWorkout> findByUserOrderByRecordTimeDesc(User user);

    // 특정 사용자 및 ID 목록으로 조회
    List<SquatWorkout> findByUserAndIdIn(User user, List<Long> ids);

    // 특정 사용자 및 날짜 범위로 조회
    List<SquatWorkout> findByUserAndRecordTimeBetween(User user, LocalDateTime start, LocalDateTime end);

    // ID 내림차순(최신순) 조회 메서드
    List<SquatWorkout> findByUserOrderByIdDesc(User user);
}