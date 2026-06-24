package com.squat.server.model;

import jakarta.persistence.*;

/// 유저 정보
@Entity
@Table(name = "user")
public class User {
    // PK
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) // Auto Increment로 줄 것
    private Long id;
    // 아이디
    @Column(nullable = false, unique = true, length = 50) // NOT NULL, 중복 X
    private String username;
    // 비밀번호
    @Column(nullable = false, length = 255)
    private String password;
    // 이름
    @Column(nullable = false, length = 50)
    private String name;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

}
