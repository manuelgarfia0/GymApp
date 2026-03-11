package com.manuel.gym_api.dto;

public class TokenDTO {
    private String token;

    // Constructor por defecto
    public TokenDTO() {}

    // Constructor con parámetros
    public TokenDTO(String token) {
        this.token = token;
    }

    // Getters y Setters
    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    @Override
    public String toString() {
        return "TokenDTO{" +
                "token='" + (token != null ? token.substring(0, Math.min(20, token.length())) + "..." : "null") + '\'' +
                '}';
    }
}