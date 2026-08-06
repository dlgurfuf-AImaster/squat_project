package com.squat.server.dto;

public class LoginResponse {
    private String token;
    private String name;

    public LoginResponse() {}

    public LoginResponse(String token, String name) {
        this.token = token;
        this.name = name;
    }

    public String getToken() { return token; }
    public String getName() { return name; }
}
