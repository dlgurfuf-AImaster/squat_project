package com.squat.server.dto;

/// 단일, 장기 분석 공통 응답 DTO
public class CoachingResponse {
    private String coachingType; // "SINGLE" 또는 "AGGREGATE"
    private int totalSessions;   // 분석 대상 세트 수
    private int totalSuccessCount;
    private int totalWaistErrorCount;
    private int totalDepthErrorCount;
    private int totalGoodMorningCount;
    private String coachingMessage;

    public CoachingResponse() {}

    public CoachingResponse(String coachingType, int totalSessions, int totalSuccessCount,
                            int totalWaistErrorCount, int totalDepthErrorCount,
                            int totalGoodMorningCount, String coachingMessage) {
        this.coachingType = coachingType;
        this.totalSessions = totalSessions;
        this.totalSuccessCount = totalSuccessCount;
        this.totalWaistErrorCount = totalWaistErrorCount;
        this.totalDepthErrorCount = totalDepthErrorCount;
        this.totalGoodMorningCount = totalGoodMorningCount;
        this.coachingMessage = coachingMessage;
    }

    // Getter & Setter
    public String getCoachingType() { return coachingType; }
    public int getTotalSessions() { return totalSessions; }
    public int getTotalSuccessCount() { return totalSuccessCount; }
    public int getTotalWaistErrorCount() { return totalWaistErrorCount; }
    public int getTotalDepthErrorCount() { return totalDepthErrorCount; }
    public int getTotalGoodMorningCount() { return totalGoodMorningCount; }
    public String getCoachingMessage() { return coachingMessage; }
}