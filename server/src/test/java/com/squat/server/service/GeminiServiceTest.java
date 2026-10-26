package com.squat.server.service;

import com.squat.server.dto.AggregateCoachingSession;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class GeminiServiceTest {

    private final GeminiService geminiService = new GeminiService();

    @Test
    void 시간_정보가_없어도_기록을_구성한다() {
        // given
        AggregateCoachingSession session =
                new AggregateCoachingSession(
                        null, 5, 3, 1, 1, 0
                );

        // when
        String result = geminiService.buildSessionDetails(
                List.of(session)
        );

        // then
        assertTrue(result.contains("시간 정보 없음"));
        assertTrue(result.contains("전체: 5"));
        assertTrue(result.contains("성공: 3 (60.0%)"));
    }

    @Test
    void 시도_횟수가_0이면_오류_비율을_계산하지_않는다() {
        // given
        AggregateCoachingSession session =
                new AggregateCoachingSession(
                        "2026-10-26 15:00", 0, 0, 0, 0, 0
                );

        // when
        String result = geminiService.buildSessionDetails(
                List.of(session)
        );

        // then
        assertTrue(result.contains("전체: 0"));
        assertTrue(result.contains("계산 불가"));
        assertFalse(result.contains("NaN"));
        assertFalse(result.contains("Infinity"));
    }

    @Test
    void 여러_오류_유형을_각각_표시한다() {
        // given
        AggregateCoachingSession session =
                new AggregateCoachingSession(
                        "2026-10-26 14:30", 10, 6, 3, 2, 1
                );

        // when
        String result = geminiService.buildSessionDetails(
                List.of(session)
        );

        // then
        assertTrue(result.contains("허리 오류: 3 (30.0%)"));
        assertTrue(result.contains("깊이 오류: 2 (20.0%)"));
        assertTrue(result.contains("빠른 수행 오류: 1 (10.0%)"));
    }
}