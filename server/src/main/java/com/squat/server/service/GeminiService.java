package com.squat.server.service;

import com.google.genai.Client;
import com.google.genai.types.GenerateContentResponse;
import com.squat.server.dto.AggregateCoachingSession;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;

@Service
public class GeminiService {

    @Value("${gemini.api.key:}")
    private String apiKey;

    private Client client;

    @PostConstruct
    public void init() {
        if (apiKey != null && !apiKey.isBlank()) {
            this.client = Client.builder().apiKey(apiKey).build();
        }
    }

    // 1. 단일 세트 피드백
    public String generateSingleCoaching(int successCount, int waistErrorCount, int depthErrorCount, int fastRepCount) {
        String prompt = String.format(
                """
                        You are a friendly and professional AI fitness trainer.
                        Here is the result of the member's just-completed 1-set squat:
                        - Successful reps: %d | Excessive forward lean: %d | Shallow squat: %d | Fast performance: %d
        
                        [Feedback Guidelines]
                        - Base all feedback strictly on the provided squat measurements.
                        - Never invent, assume, or mention problems that are not represented in the provided data.
                        - Prioritize the error type with the highest occurrence when determining the main issue.
                        - If multiple error types occur, focus primarily on the most frequent error while briefly addressing other meaningful errors when appropriate.
                        - Focus the feedback on what the member should change or maintain in the very next set.
                        - Each tip should connect the detected error to a specific movement and an immediately actionable correction.
                        - Avoid vague advice such as "be careful", "maintain good posture", or "try harder".
                        - "Excessive forward lean" means the torso leans too far forward during the squat.
                        - "Shallow squat" means the squat does not reach sufficient depth.
                        - "Fast performance" means the squat repetition was performed too quickly, preventing sufficient controlled movement and holding throughout the repetition.
        
                        [Formatting Rules]
                        1. CRITICAL: You MUST write the entire response in Korean.
                        2. Start directly with the content without any intro, greetings, or concluding remarks.
                        3. Line 1: Write an ultra-concise, high-impact punchline slogan in Korean (under 7 words).
                           - VARIETY RULE: Do not reuse static sentences. Dynamically express the slogan in Korean using varied synonyms, action verbs, and natural expressions so each response feels unique.
                           - Concept Variations for Line 1:
                             * Shallow squat main error: Dynamically vary between Korean concepts like "pushing depth to the limit", "focusing on full depth", or "staying low until the end".
                             * Fast performance main error: Dynamically vary between Korean concepts like "slow down and control the movement", "move with deliberate control", or "focus on a steady tempo".
                             * High success / No errors: Dynamically vary between Korean concepts like "perfect tension & keep this feel", "great form onto the next set", or "maintaining this exact trajectory".
                        4. From line 2 onwards: Provide 2-3 bullet points (- ) giving clear one-point cues/tips for the next set in Korean using varied, natural vocabulary.
                        5. Never use emojis. Use bold text (**keyword**) for key terms to improve readability.""",
                successCount, waistErrorCount, depthErrorCount, fastRepCount
        );

        return callGeminiApi(prompt);
    }

    // 2. 종합 세트 피드백
    public String generateAggregateCoaching(
            List<AggregateCoachingSession> sessions,
            int totalSessions,
            int totalCount,
            int successCount,
            int waistErrorCount,
            int depthErrorCount,
            int fastRepCount
    ) {
        double accuracy = totalCount > 0
                ? ((double) successCount / totalCount) * 100
                : 0;

        String sessionDetails = sessions.stream()
                .map(session -> {
                    int count = session.getTotalCount();

                    String successRate = formatRate(
                            session.getSuccessCount(), count
                    );
                    String waistRate = formatRate(
                            session.getWaistErrorCount(), count
                    );
                    String depthRate = formatRate(
                            session.getDepthErrorCount(), count
                    );
                    String fastRate = formatRate(
                            session.getFastRepCount(), count
                    );

                    String time = session.getRecordTime() == null
                            ? "시간 정보 없음"
                            : session.getRecordTime();

                    return String.format(
                            Locale.ROOT,
                            "- 시간: %s | 전체: %d | 성공: %d (%.1f%%) "
                                    + "| 허리 오류: %d (%s) "
                                    + "| 깊이 오류: %d (%s) "
                                    + "| 빠른 수행 오류: %d (%s)",
                            time,
                            count,
                            session.getSuccessCount(),
                            count > 0
                                    ? session.getSuccessCount() * 100.0 / count
                                    : 0.0,
                            session.getWaistErrorCount(),
                            waistRate,
                            session.getDepthErrorCount(),
                            depthRate,
                            session.getFastRepCount(),
                            fastRate
                    );
                })
                .collect(Collectors.joining("\n"));

        String prompt = String.format(
                Locale.ROOT,
                """
                        You are a professional AI fitness trainer.
                        
                        The member selected %d workout records.
                        The records below are ordered chronologically where timestamps
                        are available. Records without timestamps are listed last.
                        
                        [Individual workout records]
                        %s
                        
                        [Overall totals]
                        - Total workout records: %d
                        - Total squat attempts: %d
                        - Successful reps: %d (Success rate: %.1f%%)
                        - Excessive forward lean: %d
                        - Shallow squat: %d
                        - Fast performance: %d
                        
                        [Analysis Guidelines]
                        - Write the entire response in Korean.
                        - Base every conclusion strictly on the provided data.
                        - Analyze each error type independently because multiple error
                          types can occur during the same squat repetition.
                        - Never add the three error counts together as if they were
                          mutually exclusive.
                        - Compare both raw counts and per-record rates. A rate is
                          unavailable when the record has zero attempts.
                        - Identify error types that appear repeatedly across multiple
                          timestamped records.
                        - Describe improvement or worsening only when the chronological
                          data supports that conclusion.
                        - If there are too few timestamped records to establish a trend,
                          do not infer unsupported changes. Do not mention data insufficiency
                          or the lack of a long-term trend in the user-facing response.
                        - Records without timestamps may contribute to overall totals,
                          but must not be used to infer chronological trends.
                        - Do not infer causes that are not supported by the measurements.
                        - Give practical, specific movement corrections.
                        - "Excessive forward lean" means the torso leans too far forward.
                        - "Shallow squat" means the squat does not reach sufficient depth.
                        - "Fast performance" means the repetition was performed too quickly
                          to maintain controlled movement.
                        
                        [Formatting Rules]
                        1. Start directly with a concise Korean slogan under 7 words.
                        2. Follow with 2-3 Korean bullet points.
                        3. Prioritize the most meaningful recurring error or data-supported trend.
                        4. Each bullet must present one key finding and one actionable correction.
                        5. Use bold text for key terms. Do not use emojis, greetings, or concluding remarks.
                        6. Keep the response concise and information-dense. Avoid repetition, unnecessary background, and data limitations that do not affect practical recommendations.
                        """,
                totalSessions,
                sessionDetails,
                totalSessions,
                totalCount,
                successCount,
                accuracy,
                waistErrorCount,
                depthErrorCount,
                fastRepCount
        );

        return callGeminiApi(prompt);
    }

    private String formatRate(int errorCount, int totalCount) {
        if (totalCount <= 0) {
            return "계산 불가";
        }

        return String.format(
                Locale.ROOT,
                "%.1f%%",
                errorCount * 100.0 / totalCount
        );
    }

    // 공식 Gen AI SDK 호출 메서드
    private String callGeminiApi(String prompt) {
        if (client == null) {
            if (apiKey != null && !apiKey.isBlank()) {
                client = Client.builder().apiKey(apiKey).build();
            } else {
                System.err.println("Gemini API Key가 설정되지 않았습니다.");
                return null;
            }
        }

        int maxRetries = 3;
        int retryDelayMs = 2000;

        for (int attempt = 1; attempt <= maxRetries; attempt++) {
            try {
                GenerateContentResponse response = client.models.generateContent(
                        "gemini-3.5-flash-lite",
                        prompt,
                        null
                );

                if (response != null && response.text() != null) {
                    return response.text();
                }
            } catch (Exception e) {
                String errorMsg = e.getMessage() != null ? e.getMessage() : "";
                System.err.println("Gemini SDK 호출 시도 (" + attempt + "/" + maxRetries + ") 실패: " + errorMsg);

                if (errorMsg.contains("429") || errorMsg.contains("RESOURCE_EXHAUSTED")) {
                    System.err.println("쿼터 한도 초과(429). 즉시 처리를 중단합니다.");
                    return null;
                }

                if (attempt == maxRetries) {
                    System.err.println("Gemini SDK 최종 호출 실패 (최대 재시도 횟수 초과)");
                    return null;
                }

                try {
                    Thread.sleep(retryDelayMs);
                    retryDelayMs *= 2;
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    break;
                }
            }
        }

        return null;
    }
}