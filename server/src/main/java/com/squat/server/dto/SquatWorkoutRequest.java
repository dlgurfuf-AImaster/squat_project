package com.squat.server.dto;

public class SquatWorkoutRequest {
    private int successCount;
    private int waistErrorCount;
    private int depthErrorCount;
    private int goodMorningCount;

    // Getter & Setter
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
}