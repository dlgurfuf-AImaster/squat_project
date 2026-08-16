package com.squat.server.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.squat.server.model.SquatWorkout;
import java.time.LocalDateTime;

public class SquatWorkoutResponse {
    private Long id;
    private String uuid;
    private int totalCount;
    private int successCount;
    private int waistErrorCount;
    private int depthErrorCount;
    private int goodMorningCount;
    private String coachingMessage;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime recordTime;

    public SquatWorkoutResponse() {
    }

    public SquatWorkoutResponse(Long id, String uuid, int totalCount, int successCount, int waistErrorCount,
                                int depthErrorCount, int goodMorningCount, String coachingMessage, LocalDateTime recordTime) {
        this.id = id;
        this.uuid = uuid;
        this.totalCount = totalCount;
        this.successCount = successCount;
        this.waistErrorCount = waistErrorCount;
        this.depthErrorCount = depthErrorCount;
        this.goodMorningCount = goodMorningCount;
        this.coachingMessage = coachingMessage;
        this.recordTime = recordTime;
    }

    // 엔티티(SquatWorkout)를 DTO로 변환하는 정적 팩토리 메서드
    public static SquatWorkoutResponse from(SquatWorkout workout) {
        return new SquatWorkoutResponse(
                workout.getId(),
                workout.getUuid(),
                workout.getTotalCount(),
                workout.getSuccessCount(),
                workout.getWaistErrorCount(),
                workout.getDepthErrorCount(),
                workout.getGoodMorningCount(),
                workout.getCoachingMessage(),
                workout.getRecordTime()
        );
    }

    // --- Getter & Setter ---
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getUuid() { return uuid; }
    public void setUuid(String uuid) { this.uuid = uuid; }

    public int getTotalCount() { return totalCount; }
    public void setTotalCount(int totalCount) { this.totalCount = totalCount; }

    public int getSuccessCount() { return successCount; }
    public void setSuccessCount(int successCount) { this.successCount = successCount; }

    public int getWaistErrorCount() { return waistErrorCount; }
    public void setWaistErrorCount(int waistErrorCount) { this.waistErrorCount = waistErrorCount; }

    public int getDepthErrorCount() { return depthErrorCount; }
    public void setDepthErrorCount(int depthErrorCount) { this.depthErrorCount = depthErrorCount; }

    public int getGoodMorningCount() { return goodMorningCount; }
    public void setGoodMorningCount(int goodMorningCount) { this.goodMorningCount = goodMorningCount; }

    public String getCoachingMessage() { return coachingMessage; }
    public void setCoachingMessage(String coachingMessage) { this.coachingMessage = coachingMessage; }

    public LocalDateTime getRecordTime() { return recordTime; }
    public void setRecordTime(LocalDateTime recordTime) { this.recordTime = recordTime; }
}