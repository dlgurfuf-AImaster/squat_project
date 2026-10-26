package com.squat.server.dto;

public class AggregateCoachingSession {

    private final String recordTime;
    private final int totalCount;
    private final int successCount;
    private final int waistErrorCount;
    private final int depthErrorCount;
    private final int fastRepCount;

    public AggregateCoachingSession(
            String recordTime,
            int totalCount,
            int successCount,
            int waistErrorCount,
            int depthErrorCount,
            int fastRepCount
    ) {
        this.recordTime = recordTime;
        this.totalCount = totalCount;
        this.successCount = successCount;
        this.waistErrorCount = waistErrorCount;
        this.depthErrorCount = depthErrorCount;
        this.fastRepCount = fastRepCount;
    }

    public String getRecordTime() {
        return recordTime;
    }

    public int getTotalCount() {
        return totalCount;
    }

    public int getSuccessCount() {
        return successCount;
    }

    public int getWaistErrorCount() {
        return waistErrorCount;
    }

    public int getDepthErrorCount() {
        return depthErrorCount;
    }

    public int getFastRepCount() {
        return fastRepCount;
    }
}