package com.squat.server.dto;

import com.squat.server.model.SquatWorkout;
import java.time.LocalDateTime;

public class SquatWorkoutResponse {
    private Long id;
    private int totalCount;
    private int successCount;
    private int waistErrorCount;
    private int depthErrorCount;
    private int goodMorningCount;
    private String coachingMessage;
    private LocalDateTime endTime;

    public SquatWorkoutResponse() {
    }

    public SquatWorkoutResponse(Long id, int totalCount, int successCount, int waistErrorCount,
                                int depthErrorCount, int goodMorningCount, String coachingMessage, LocalDateTime endTime) {
        this.id = id;
        this.totalCount = totalCount;
        this.successCount = successCount;
        this.waistErrorCount = waistErrorCount;
        this.depthErrorCount = depthErrorCount;
        this.goodMorningCount = goodMorningCount;
        this.coachingMessage = coachingMessage;
        this.endTime = endTime;
    }

    // 엔티티(SquatWorkout)를 DTO로 변환하는 정적 팩토리 메서드
    public static SquatWorkoutResponse from(SquatWorkout workout) {
        return new SquatWorkoutResponse(
                workout.getId(),
                workout.getTotalCount(),
                workout.getSuccessCount(),
                workout.getWaistErrorCount(),
                workout.getDepthErrorCount(),
                workout.getGoodMorningCount(),
                workout.getCoachingMessage(),
                workout.getEndTime()
        );
    }

    // --- Getter & Setter ---
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public int getTotalCount() {
        return totalCount;
    }

    public void setTotalCount(int totalCount) {
        this.totalCount = totalCount;
    }

    public int getSuccessCount() {
        return successCount;
    }

    public void setSuccessCount(int successCount) {
        this.successCount = successCount;
    }

    public int getWaistErrorCount() {
        return waistErrorCount;
    }

    public void setWaistErrorCount(int waistErrorCount) {
        this.waistErrorCount = waistErrorCount;
    }

    public int getDepthErrorCount() {
        return depthErrorCount;
    }

    public void setDepthErrorCount(int depthErrorCount) {
        this.depthErrorCount = depthErrorCount;
    }

    public int getGoodMorningCount() {
        return goodMorningCount;
    }

    public void setGoodMorningCount(int goodMorningCount) {
        this.goodMorningCount = goodMorningCount;
    }

    public String getCoachingMessage() {
        return coachingMessage;
    }

    public void setCoachingMessage(String coachingMessage) {
        this.coachingMessage = coachingMessage;
    }

    public LocalDateTime getEndTime() {
        return endTime;
    }

    public void setEndTime(LocalDateTime endTime) {
        this.endTime = endTime;
    }
}