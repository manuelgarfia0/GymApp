package com.manuel.gym_api.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.manuel.gym_api.dto.LoginDTO;
import com.manuel.gym_api.dto.TokenDTO;
import com.manuel.gym_api.model.User;
import com.manuel.gym_api.security.TokenService;

import jakarta.validation.Valid;
import java.util.Map;
import java.util.HashMap;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthenticationManager authenticationManager;
    private final TokenService tokenService;

    public AuthController(AuthenticationManager authenticationManager, 
                         TokenService tokenService) {
        this.authenticationManager = authenticationManager;
        this.tokenService = tokenService;
    }

    @PostMapping("/login")
    public ResponseEntity<TokenDTO> login(@RequestBody @Valid LoginDTO loginDTO) {
        try {
            System.out.println("🔄 AuthController: Procesando login para usuario: " + loginDTO.getUsername());
            
            // Creamos un token interno de Spring con usuario y contraseña
            UsernamePasswordAuthenticationToken usernamePassword = 
                new UsernamePasswordAuthenticationToken(loginDTO.getUsername(), loginDTO.getPassword());
            
            System.out.println("🔐 AuthController: Autenticando usuario...");
            
            // El AuthenticationManager irá automáticamente al AuthService que creamos a
            // buscar al usuario y usará el PasswordEncoder para comprobar que la contraseña coincide.
            Authentication auth = this.authenticationManager.authenticate(usernamePassword);
            
            System.out.println("✅ AuthController: Usuario autenticado exitosamente");
            
            // Si todo fue bien, generamos nuestro JWT real
            var token = tokenService.generateToken((User) auth.getPrincipal());
            
            System.out.println("🎫 AuthController: Token JWT generado exitosamente");
            
            return ResponseEntity.ok(new TokenDTO(token));
        } catch (Exception e) {
            // Log del error para debugging
            System.err.println("❌ Error en login: " + e.getMessage());
            e.printStackTrace();
            throw e;
        }
    }

    @PostMapping("/register")
    public ResponseEntity<Map<String, String>> register(@RequestBody Map<String, String> registrationData) {
        try {
            System.out.println("🔄 AuthController: Procesando registro...");
            
            Map<String, String> response = new HashMap<>();
            response.put("status", "success");
            response.put("message", "Registration endpoint - not implemented yet");
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            // Log del error para debugging
            System.err.println("❌ Error en register: " + e.getMessage());
            e.printStackTrace();
            throw e;
        }
    }

    @GetMapping("/me")
    public ResponseEntity<Map<String, Object>> getCurrentUser(Authentication authentication) {
        try {
            System.out.println("🔄 AuthController: Obteniendo usuario actual...");
            
            // Obtener el usuario autenticado desde el contexto de seguridad
            if (authentication != null && authentication.getPrincipal() instanceof User) {
                User user = (User) authentication.getPrincipal();
                
                System.out.println("✅ AuthController: Usuario encontrado: " + user.getUsername());
                
                // Crear respuesta que coincida con lo que espera Flutter
                Map<String, Object> response = new HashMap<>();
                response.put("id", user.getId());
                response.put("username", user.getUsername());
                response.put("email", user.getEmail());
                response.put("isPremium", user.isPremium());
                response.put("publicProfile", user.isPublicProfile());
                response.put("languagePreference", user.getLanguagePreference());
                response.put("createdAt", user.getCreatedAt() != null ? user.getCreatedAt().toString() : null);
                
                return ResponseEntity.ok(response);
            } else {
                System.out.println("❌ AuthController: No hay usuario autenticado");
                // Si no hay usuario autenticado, devolver error 401
                return ResponseEntity.status(401).build();
            }
        } catch (Exception e) {
            // Log del error para debugging
            System.err.println("❌ Error en getCurrentUser: " + e.getMessage());
            e.printStackTrace();
            throw e;
        }
    }

    // Endpoints temporales para testing con GET (los diagnósticos usan GET)
    @GetMapping("/login")
    public ResponseEntity<Map<String, String>> loginInfo() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "info");
        response.put("message", "Use POST method for login");
        response.put("endpoint", "/api/auth/login");
        response.put("method", "POST");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/register")
    public ResponseEntity<Map<String, String>> registerInfo() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "info");
        response.put("message", "Use POST method for registration");
        response.put("endpoint", "/api/auth/register");
        response.put("method", "POST");
        return ResponseEntity.ok(response);
    }
}