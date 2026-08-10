package com.squat.server.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.LocalDateTime;

public class SquatWorkoutRequest {
    private int successCount;
    private int waistErrorCount;
    private int depthErrorCount;
    private int goodMorningCount;

    @JsonProperty("recordTime")
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime recordTime;

    public SquatWorkoutRequest() {}

    // Getter & Setter
    public int getSuccessCount() { return successCount; }
    public void setSuccessCount(int successCount) { this.successCount = successCount; }

    public int getWaistErrorCount() { return waistErrorCount; }
    public void setWaistErrorCount(int waistErrorCount) { this.waistErrorCount = waistErrorCount; }

    public int getDepthErrorCount() { return depthErrorCount; }
    public void setDepthErrorCount(int depthErrorCount) { this.depthErrorCount = depthErrorCount; }

    public int getGoodMorningCount() { return goodMorningCount; }
    public void setGoodMorningCount(int goodMorningCount) { this.goodMorningCount = goodMorningCount; }

    public LocalDateTime getRecordTime() { return recordTime; }
    public void setRecordTime(LocalDateTime recordTime) { this.recordTime = recordTime; }

}