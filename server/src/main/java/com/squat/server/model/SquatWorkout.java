package com.squat.server.model;

import java.time.LocalDateTime;
import jakarta.persistence.*;

/// 스쿼트 정보
@Entity
@Table(name = "squat_workout")
public class SquatWorkout {
    // PK
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY) // 지연로딩. 필요한 정보만 가져올 것
    @JoinColumn(name = "user_id", nullable = false) // id 없는 기록은 존재하지 못하도록 함
    private User user;

    private int successCount; // 성공
    private int waistErrorCount; // 허리 과숙임
    private int depthErrorCount; // 얕은 스쿼트
    private int goodMorningCount; // 엉덩이 선행 횟수

    private LocalDateTime endTime; // 데이터 저장 시 시간 입력용

    @PrePersist // INSERT 전에 자동 실행
    protected void onCreate() {
        this.endTime = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
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

    public LocalDateTime getEndTime() {
        return endTime;
    }

    public void setEndTime(LocalDateTime endTime) {
        this.endTime = endTime;
    }
}
