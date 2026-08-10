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
    private final ObjectMapper objectMapper = new ObjectMapper(); // ObjectMapper 추가

    public String generateCoachingMessage(int successCount, int waistErrorCount, int depthErrorCount, int goodMorningCount) {
        String urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=" + apiKey;

        String prompt = String.format(
                "너는 친절하고 전문적인 헬스 트레이너 AI야. " +
                        "회원의 방금 스쿼트 운동 기록: 성공 %d회, 허리 과숙임 오류 %d회, 얕은 스쿼트 오류 %d회, 엉덩이 선행(굿모닝 스쿼트) 오류 %d회. " +
                        "오늘 운동에 대한 칭찬과 함께 가장 개선이 필요한 자세 오류 1가지를 포함하여 2문장 이내의 명확한 격려 피드백을 작성해줘.",
                successCount, waistErrorCount, depthErrorCount, goodMorningCount
        );

        Map<String, Object> requestBody = Map.of(
                "contents", List.of(
                        Map.of("parts", List.of(Map.of("text", prompt)))
                )
        );

        try {
            // 1. body(JsonNode.class) 대신 body(String.class)로 응답 문자열을 전달받음
            String responseBody = restClient.post()
                    .uri(URI.create(urlString))
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(requestBody)
                    .retrieve()
                    .body(String.class);

            // 2. ObjectMapper를 통해 JsonNode로 안전하게 파싱
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
            return "오늘도 스쿼트를 성공적으로 마쳤습니다! 수고하셨어요 👍";
        } catch (Exception e) {
            System.err.println("Gemini API 호출 오류: " + e.getMessage());
            return "오늘도 스쿼트를 완료했습니다! 다음 운동도 화이팅해 보세요 💪";
        }
    }
}