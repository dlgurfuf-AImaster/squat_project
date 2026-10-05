package com.squat.server.dto;

import java.util.List;

/// 장기, 다중 분석 요청 DTO
public class AggregateCoachingRequest {
    private List<String> workoutUuids;

    public AggregateCoachingRequest() {}

    public List<String> getWorkoutUuids() {
        return workoutUuids;
    }

    public void setWorkoutUuids(List<String> workoutUuids) {
        this.workoutUuids = workoutUuids;
    }
}