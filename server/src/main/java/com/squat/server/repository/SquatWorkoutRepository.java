package com.squat.server.repository;

import com.squat.server.model.SquatWorkout;
import com.squat.server.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface SquatWorkoutRepository extends JpaRepository<SquatWorkout, Long> {

    // 특정 사용자 및 UUID 목록으로 조회
    List<SquatWorkout> findByUserAndUuidIn(User user, List<String> uuids);

    // 특정 사용자 및 날짜 범위로 조회
    List<SquatWorkout> findByUserAndRecordTimeBetween(User user, LocalDateTime start, LocalDateTime end);

    // ID 내림차순(최신순) 조회 메서드
    List<SquatWorkout> findByUserOrderByIdDesc(User user);

    // 사용자 및 UUID 기준 데이터 삭제
    void deleteByUserAndUuid(User user, String uuid);

    // 사용자 및 UUID 기준 단일 운동 기록 조회
    Optional<SquatWorkout> findByUserAndUuid(User user, String uuid);
}