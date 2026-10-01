package com.squat.server.model;

import jakarta.persistence.*;

import java.util.Date;

@Entity
@Table(name = "revoked_token")
public class RevokedToken {

    // PK
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // JWT의 고유 식별자
    @Column(nullable = false, unique = true, length = 255)
    private String jti;

    // 원래 JWT가 만료되는 시간
    @Column(nullable = false)
    private Date expiresAt;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getJti() {
        return jti;
    }

    public void setJti(String jti) {
        this.jti = jti;
    }

    public Date getExpiresAt() {
        return expiresAt;
    }

    public void setExpiresAt(Date expiresAt) {
        this.expiresAt = expiresAt;
    }
}