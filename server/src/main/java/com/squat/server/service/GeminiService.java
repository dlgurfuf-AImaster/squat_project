package com.squat.server.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.net.URI;
import java.util.List;
import java.util.Map;

@Service
public class GeminiService {

    @Value("${gemini.api.key:}")
    private String apiKey;

    private final RestClient restClient = RestClient.create();
    private final ObjectMapper objectMapper = new ObjectMapper();

    // 💡 1. 단일 세트 피드백 (즉각적인 다음 세트 교정용)
    public String generateSingleCoaching(int successCount, int waistErrorCount, int depthErrorCount, int goodMorningCount) {
        String prompt = String.format(
                """
                        너는 친절하고 전문적인 헬스 트레이너 AI야.
                        회원의 방금 수행한 1세트 스쿼트 결과:
                        - 성공: %d회 | 허리 과숙임: %d회 | 얕은 스쿼트: %d회 | 엉덩이 선행(굿모닝): %d회
                        
                        [작성 규칙]
                        1. 모바일 카드 화면에 맞춰 2~3개의 불릿 포인트(- )로만 구성해줘.
                        2. 인사말('안녕하세요' 등)이나 결론 없이 바로 본문으로 시작해줘.
                        3. 방금 완료한 세트에 대한 **짧은 격려 1줄**을 포함해줘.
                        4. 가장 비중이 높은 오류를 교정하기 위한 **다음 세트 원포인트 큐잉(팁) 1가지**를 명확히 제시해줘. (오류가 0회라면 완벽한 자극 유지 팁 제시)
                        5. 이모지와 핵심 단어 강조(**강조**)를 활용해 가독성을 높여줘.""",
                successCount, waistErrorCount, depthErrorCount, goodMorningCount
        );

        return callGeminiApi(prompt);
    }

    // 💡 2. 장기 / 누적 세트 피드백 (습관 및 성장 추세 분석용)
    public String generateAggregateCoaching(int totalSessions, int successCount, int waistErrorCount, int depthErrorCount, int goodMorningCount) {
        int totalAttempts = successCount + waistErrorCount + depthErrorCount + goodMorningCount;
        double accuracy = totalAttempts > 0 ? ((double) successCount / totalAttempts) * 100 : 0;

        String prompt = String.format(
                """
                        너는 피트니스 전문 AI 트레이너야. 회원의 누적 스쿼트 데이터(총 %d세트) 집계 결과야:
                        - 성공: %d회 (성공률: %.1f%%)
                        - 허리 과숙임: %d회 | 얕은 스쿼트: %d회 | 엉덩이 선행(굿모닝): %d회
                        
                        [작성 규칙]
                        1. 모바일 앱에서 한눈에 읽히도록 전체 3~4개의 불릿 포인트(- )로만 작성해줘.
                        2. 인사말이나 '안녕하세요' 같은 서론/결론은 제외하고 바로 분석 결과로 들어가줘.
                        3. 가장 오류 횟수가 높은 항목의 **핵심 원인 1가지**를 명확히 짚어줘.
                        4. 앞으로의 자세 개선을 위한 **가장 핵심적인 실천 팁 1~2가지**를 추천해줘.
                        5. 이모지와 핵심 키워드 강조(**강조**)를 사용해 가독성을 높여줘.""",
                totalSessions, successCount, accuracy, waistErrorCount, depthErrorCount, goodMorningCount
        );

        return callGeminiApi(prompt);
    }

    // 💡 공통 Gemini API 호출 메서드 (재시도 로직 적용)
    private String callGeminiApi(String prompt) {
        String urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=" + apiKey;

        Map<String, Object> requestBody = Map.of(
                "contents", List.of(
                        Map.of("parts", List.of(Map.of("text", prompt)))
                )
        );

        int maxRetries = 3;
        int retryDelayMs = 1500;

        for (int attempt = 1; attempt <= maxRetries; attempt++) {
            try {
                String responseBody = restClient.post()
                        .uri(URI.create(urlString))
                        .contentType(MediaType.APPLICATION_JSON)
                        .body(requestBody)
                        .retrieve()
                        .body(String.class);

                if (responseBody != null) {
                    JsonNode response = objectMapper.readTree(responseBody);
                    if (response.has("candidates")) {
                        JsonNode candidates = response.get("candidates");
                        if (candidates.isArray() && !candidates.isEmpty()) {
                            return candidates.get(0)
                                    .get("content")
                                    .get("parts")
                                    .get(0)
                                    .get("text")
                                    .asText();
                        }
                    }
                }
            } catch (Exception e) {
                System.err.println("Gemini API 호출 시도 (" + attempt + "/" + maxRetries + ") 실패: " + e.getMessage());

                // 마지막 시도 실패 시 null 반환
                if (attempt == maxRetries) {
                    System.err.println("Gemini API 최종 호출 실패. null을 반환합니다.");
                    return null;
                }

                try {
                    Thread.sleep(retryDelayMs);
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    break;
                }
            }
        }

        return null; // 예외 발생 및 재시도 실패 시 null 반환
    }
}