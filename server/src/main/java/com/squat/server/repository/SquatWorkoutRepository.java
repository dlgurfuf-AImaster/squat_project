package com.squat.server.repository;

import com.squat.server.model.SquatWorkout;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SquatWorkoutRepository extends JpaRepository<SquatWorkout, Long> {

    List<SquatWorkout> findByUserIdOrderByRecordTimeDesc(Long userId);
}
