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
import com.manuel.gym_api.dto.UserRegistrationDTO;
import com.manuel.gym_api.dto.UserDTO;
import com.manuel.gym_api.model.User;
import com.manuel.gym_api.security.TokenService;
import com.manuel.gym_api.service.UserService;

import jakarta.validation.Valid;
import java.util.Map;
import java.util.HashMap;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthenticationManager authenticationManager;
    private final TokenService tokenService;
    private final UserService userService;

    public AuthController(AuthenticationManager authenticationManager, 
                         TokenService tokenService,
                         UserService userService) {
        this.authenticationManager = authenticationManager;
        this.tokenService = tokenService;
        this.userService = userService;
    }

    @PostMapping("/login")
    public ResponseEntity<TokenDTO> login(@RequestBody @Valid LoginDTO loginDTO) {
        try {
            // Creamos un token interno de Spring con usuario y contraseña
            UsernamePasswordAuthenticationToken usernamePassword = 
                new UsernamePasswordAuthenticationToken(loginDTO.getUsername(), loginDTO.getPassword());
            
            // El AuthenticationManager irá automáticamente al AuthService que creamos a
            // buscar al usuario y usará el PasswordEncoder para comprobar que la contraseña coincide.
            Authentication auth = this.authenticationManager.authenticate(usernamePassword);
            
            // Si todo fue bien, generamos nuestro JWT real
            var token = tokenService.generateToken((User) auth.getPrincipal());
            return ResponseEntity.ok(new TokenDTO(token));
        } catch (Exception e) {
            // Log del error para debugging
            System.err.println("Error en login: " + e.getMessage());
            e.printStackTrace();
            throw e;
        }
    }

    @PostMapping("/register")
    public ResponseEntity<Map<String, String>> register(@RequestBody @Valid UserRegistrationDTO registrationDTO) {
        try {
            UserDTO userDTO = userService.registerUser(registrationDTO);
            
            Map<String, String> response = new HashMap<>();
            response.put("status", "success");
            response.put("message", "User registered successfully");
            response.put("userId", userDTO.getId().toString());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            // Log del error para debugging
            System.err.println("Error en register: " + e.getMessage());
            e.printStackTrace();
            throw e;
        }
    }

    @GetMapping("/me")
    public ResponseEntity<UserDTO> getCurrentUser(Authentication authentication) {
        try {
            // Obtener el usuario autenticado desde el contexto de seguridad
            if (authentication != null && authentication.getPrincipal() instanceof User) {
                User user = (User) authentication.getPrincipal();
                
                // Convertir a DTO para la respuesta
                UserDTO userDTO = new UserDTO();
                userDTO.setId(user.getId());
                userDTO.setUsername(user.getUsername());
                userDTO.setEmail(user.getEmail());
                
                // Manejar isPremium con diferentes posibles nombres de métodos
                try {
                    Boolean isPremium = null;
                    // Intentar diferentes nombres de métodos
                    try {
                        isPremium = user.isPremium();
                    } catch (Exception e1) {
                        try {
                            isPremium = user.getIsPremium();
                        } catch (Exception e2) {
                            try {
                                isPremium = (Boolean) user.getClass().getMethod("getPremium").invoke(user);
                            } catch (Exception e3) {
                                isPremium = false; // Valor por defecto
                            }
                        }
                    }
                    userDTO.setIsPremium(isPremium != null ? isPremium : false);
                } catch (Exception e) {
                    userDTO.setIsPremium(false);
                }
                
                // Manejar publicProfile con diferentes posibles nombres de métodos
                try {
                    Boolean publicProfile = null;
                    // Intentar diferentes nombres de métodos
                    try {
                        publicProfile = user.isPublicProfile();
                    } catch (Exception e1) {
                        try {
                            publicProfile = user.getPublicProfile();
                        } catch (Exception e2) {
                            publicProfile = true; // Valor por defecto
                        }
                    }
                    userDTO.setPublicProfile(publicProfile != null ? publicProfile : true);
                } catch (Exception e) {
                    userDTO.setPublicProfile(true);
                }
                
                userDTO.setLanguagePreference(user.getLanguagePreference());
                userDTO.setCreatedAt(user.getCreatedAt() != null ? user.getCreatedAt().toString() : null);
                
                return ResponseEntity.ok(userDTO);
            } else {
                // Si no hay usuario autenticado, devolver error 401
                return ResponseEntity.status(401).build();
            }
        } catch (Exception e) {
            // Log del error para debugging
            System.err.println("Error en getCurrentUser: " + e.getMessage());
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