package com.squat.server.dto;

import java.time.LocalDate;
import java.util.List;

/// 장기, 다중 분석 요청 DTO
public class AggregateCoachingRequest {
    private List<Long> workoutIds; // 선택지 1: 개별 ID 목록
    private LocalDate startDate;   // 선택지 2: 시작일
    private LocalDate endDate;     // 선택지 2: 종료일
    private Boolean recent30Days;  // 선택지 3: 최근 30일 명시적 선택 플래그 (true)

    public AggregateCoachingRequest() {}

    public List<Long> getWorkoutIds() { return workoutIds; }
    public void setWorkoutIds(List<Long> workoutIds) { this.workoutIds = workoutIds; }

    public LocalDate getStartDate() { return startDate; }
    public void setStartDate(LocalDate startDate) { this.startDate = startDate; }

    public LocalDate getEndDate() { return endDate; }
    public void setEndDate(LocalDate endDate) { this.endDate = endDate; }

    public Boolean getRecent30Days() { return recent30Days; }
    public void setRecent30Days(Boolean recent30Days) { this.recent30Days = recent30Days; }
}