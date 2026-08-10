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
                "너는 친절하고 전문적인 헬스 트레이너 AI야. " +
                        "회원의 방금 1회 차 스쿼트 기록: 성공 %d회, 허리 과숙임 오류 %d회, 얕은 스쿼트 오류 %d회, 엉덩이 선행(굿모닝 스쿼트) 오류 %d회. " +
                        "오늘 운동에 대한 칭찬과 함께 다음 세트에서 바로 적용할 수 있는 가장 중요한 자세 교정 포인트 1가지를 포함하여 2~3문장 이내의 명확한 피드백을 작성해줘.",
                successCount, waistErrorCount, depthErrorCount, goodMorningCount
        );

        return callGeminiApi(prompt);
    }

    // 💡 2. 장기 / 누적 세트 피드백 (습관 및 성장 추세 분석용)
    public String generateAggregateCoaching(int totalSessions, int successCount, int waistErrorCount, int depthErrorCount, int goodMorningCount) {
        int totalAttempts = successCount + waistErrorCount + depthErrorCount + goodMorningCount;
        double accuracy = totalAttempts > 0 ? ((double) successCount / totalAttempts) * 100 : 0;

        String prompt = String.format(
                "너는 피트니스 데이터 분석 전문 AI 트레이너야. " +
                        "회원의 누적 스쿼트 데이터(총 %d세트) 집계 결과야:\n" +
                        "- 총 성공: %d회 (전체 성공률: %.1f%%)\n" +
                        "- 허리 과숙임 오류 총합: %d회\n" +
                        "- 얕은 스쿼트 오류 총합: %d회\n" +
                        "- 엉덩이 선행(굿모닝) 오류 총합: %d회\n\n" +
                        "이 장기 데이터를 바탕으로:\n" +
                        "1. 회원에게 가장 자주 나타나는 주된 자세 오류 습관 분석 및 원인 설명\n" +
                        "2. 앞으로의 지속적인 스쿼트 자세 개선을 위한 종합 가이드\n" +
                        "위 내용을 포함하여 보기 쉽게 문단을 나누어 친절한 톤으로 피드백을 작성해줘.",
                totalSessions, successCount, accuracy, waistErrorCount, depthErrorCount, goodMorningCount
        );

        return callGeminiApi(prompt);
    }

    // 💡 공통 Gemini API 호출 메서드
    private String callGeminiApi(String prompt) {
        String urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=" + apiKey;

        Map<String, Object> requestBody = Map.of(
                "contents", List.of(
                        Map.of("parts", List.of(Map.of("text", prompt)))
                )
        );

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
            return "운동 기록 분석이 완료되었습니다! 계속해서 좋은 자세를 유지해 보세요 👍";
        } catch (Exception e) {
            System.err.println("Gemini API 호출 오류: " + e.getMessage());
            return "스쿼트 기록이 성공적으로 분석되었습니다! 다음 운동도 화이팅해 보세요 💪";
        }
    }
}