package com.squat.server.model;

import java.time.LocalDateTime;
import jakarta.persistence.*;

/// 스쿼트 정보
@Entity
// 사용자별 최신 기록(id DESC) 조회를 위한 복합 인덱스(Index) 설정 추가
@Table(
        name = "squat_workout",
        indexes = {
                @Index(name = "idx_user_id_id_desc", columnList = "user_id, id DESC")
        }
)
public class SquatWorkout {
    // PK
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY) // 지연로딩. 필요한 정보만 가져올 것
    @JoinColumn(name = "user_id", nullable = false) // id 없는 기록은 존재하지 못하도록 함
    private User user;

    private int totalCount; // 총 횟수 (성공 + 모든 오류 횟수 합산)
    private int successCount; // 성공
    private int waistErrorCount; // 허리 과숙임
    private int depthErrorCount; // 얕은 스쿼트
    private int goodMorningCount; // 엉덩이 선행 횟수

    @Column(columnDefinition = "TEXT")
    private String coachingMessage; // AI 코칭 메세지 (긴 텍스트라 TEXT타입)

    private LocalDateTime recordTime; // 앱에서 전송한 운동 시간

    @PrePersist // INSERT 전에 자동 실행
    protected void onCreate() {
        // DB 저장 직전 성공 및 오류 횟수를 자동으로 더해 totalCount 세팅
        this.totalCount = this.successCount + this.waistErrorCount + this.depthErrorCount + this.goodMorningCount;
    }

    // --- Getter & Setter ---
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

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