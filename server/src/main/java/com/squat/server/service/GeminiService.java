package com.squat.server.service;

import com.google.genai.Client;
import com.google.genai.types.GenerateContentResponse;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

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

    // 💡 1. 단일 세트 피드백 (영문 프롬프트 -> 한국어 응답 지정)
    public String generateSingleCoaching(int successCount, int waistErrorCount, int depthErrorCount, int goodMorningCount) {
        String prompt = String.format(
                """
                        You are a friendly and professional AI fitness trainer.
                        Here is the result of the member's just-completed 1-set squat:
                        - Successful reps: %d | Excessive forward lean: %d | Shallow squat: %d | Upper-body-first movement: %d
        
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
                        - "Upper-body-first movement" means the upper body initiates the movement before the lower body, causing the torso to move ahead of the lower body.
        
                        [Formatting Rules]
                        1. CRITICAL: You MUST write the entire response in Korean.
                        2. Start directly with the content without any intro, greetings, or concluding remarks.
                        3. Line 1: Write an ultra-concise, high-impact punchline slogan in Korean (under 7 words).
                           - VARIETY RULE: Do not reuse static sentences. Dynamically express the slogan in Korean using varied synonyms, action verbs, and natural expressions so each response feels unique.
                           - Concept Variations for Line 1:
                             * Shallow squat main error: Dynamically vary between Korean concepts like "pushing depth to the limit", "focusing on full depth", or "staying low until the end".
                             * Upper-body-first main error: Dynamically vary between Korean concepts like "chest up & core engaged", "keeping torso upright to protect back", or "eyes forward & chest open".
                             * High success / No errors: Dynamically vary between Korean concepts like "perfect tension & keep this feel", "great form onto the next set", or "maintaining this exact trajectory".
                        4. From line 2 onwards: Provide 2-3 bullet points (- ) giving clear one-point cues/tips for the next set in Korean using varied, natural vocabulary.
                        5. Never use emojis. Use bold text (**keyword**) for key terms to improve readability.""",
                successCount, waistErrorCount, depthErrorCount, goodMorningCount
        );

        return callGeminiApi(prompt);
    }

    // 💡 2. 장기 / 누적 세트 피드백 (영문 프롬프트 -> 한국어 응답 지정)
    public String generateAggregateCoaching(int totalSessions, int successCount, int waistErrorCount, int depthErrorCount, int goodMorningCount) {
        int totalAttempts = successCount + waistErrorCount + depthErrorCount + goodMorningCount;
        double accuracy = totalAttempts > 0 ? ((double) successCount / totalAttempts) * 100 : 0;

        String prompt = String.format(
                """
                        You are a professional AI fitness trainer.
                        Here is the aggregated squat data for the member across %d sets:
                        - Successful reps: %d (Success rate: %.1f%%)
                        - Excessive forward lean: %d | Shallow squat: %d | Upper-body-first movement: %d
        
                        [Feedback Guidelines]
                        - Base all feedback strictly on the provided squat measurements.
                        - Never invent, assume, or mention problems that are not represented in the provided data.
                        - Prioritize the error type with the highest occurrence when determining the main issue.
                        - Do not rely solely on the success rate when determining the main feedback.
                        - Even when the success rate is high, address a recurring form error if it occurs frequently.
                        - Focus on recurring patterns across the entire session rather than isolated errors from a single set.
                        - Each tip should connect the detected error to a specific movement and an immediately actionable correction.
                        - Avoid vague advice such as "be careful", "maintain good posture", or "try harder".
                        - "Excessive forward lean" means the torso leans too far forward during the squat.
                        - "Shallow squat" means the squat does not reach sufficient depth.
                        - "Upper-body-first movement" means the upper body initiates the movement before the lower body, causing the torso to move ahead of the lower body.
        
                        [Formatting Rules]
                        1. CRITICAL: You MUST write the entire response in Korean.
                        2. Start directly with the analysis without any intro, greetings, or concluding remarks.
                        3. Line 1: Write an ultra-concise, high-impact punchline slogan in Korean (under 7 words) summarizing overall performance.
                           - VARIETY RULE: Avoid static boilerplate phrases. Actively use creative Korean phrasing, synonyms, and varied vocabulary so each session analysis feels fresh and distinct.
                           - Concept Variations for Line 1:
                             * Shallow squat dominant: Dynamically vary between Korean concepts like "today's key is depth", "completing full range of motion", or "securing depth for lower body activation".
                             * Upper-body-first dominant: Dynamically vary between Korean concepts like "upright posture is top priority today", "chest open & tension maintained", or "aligning chest and back posture".
                             * Overall good posture: Dynamically vary between Korean concepts like "stable form maintained", "perfect tempo & execution", or "keep this exact momentum".
                        4. Line break, then write 2-3 bullet points (- ) in Korean explaining main causes and practical actionable tips with fresh, varied wording.
                        5. Never use emojis. Use bold text (**keyword**) for key terms to improve readability.""",
                totalSessions, successCount, accuracy, waistErrorCount, depthErrorCount, goodMorningCount
        );

        return callGeminiApi(prompt);
    }

    // 💡 공식 Gen AI SDK 호출 메서드
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