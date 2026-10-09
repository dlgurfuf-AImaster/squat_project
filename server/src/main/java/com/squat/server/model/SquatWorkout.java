package com.squat.server.model;

import java.time.LocalDateTime;
import jakarta.persistence.*;

/// 스쿼트 정보
@Entity
// 사용자별 최신 기록(id DESC) 조회를 위한 복합 인덱스(Index) 설정
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

    @Column(nullable = false, unique = true)
    private String uuid;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    private int totalCount; // 실제 완료한 총 스쿼트 횟수
    private int successCount; // 성공 횟수
    private int waistErrorCount; // 허리 과숙임 오류
    private int depthErrorCount; // 얕은 깊이 오류
    private int fastRepCount; // 빠른 수행 오류

    @Column(columnDefinition = "TEXT")
    private String coachingMessage; // AI 코칭 메시지

    private LocalDateTime recordTime; // 앱에서 전송한 운동 시간

    // Getter & Setter
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getUuid() { return uuid; }
    public void setUuid(String uuid) { this.uuid = uuid; }

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

    public int getFastRepCount() { return fastRepCount; }
    public void setFastRepCount(int fastRepCount) { this.fastRepCount = fastRepCount; }

    public String getCoachingMessage() { return coachingMessage; }
    public void setCoachingMessage(String coachingMessage) { this.coachingMessage = coachingMessage; }

    public LocalDateTime getRecordTime() { return recordTime; }
    public void setRecordTime(LocalDateTime recordTime) { this.recordTime = recordTime; }
}