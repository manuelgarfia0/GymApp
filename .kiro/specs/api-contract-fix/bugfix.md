# Bugfix Requirements Document

## Introduction

El sistema presenta un error crítico de contrato de comunicación entre GymApp (Flutter) y GymAPI (Spring Boot). Las peticiones HTTP desde Flutter están siendo enviadas con Content-Type 'text/plain;charset=utf-8' en lugar del Content-Type 'application/json' esperado por Spring Boot, causando errores 500 en todas las operaciones de autenticación y potencialmente en otras funcionalidades que requieren envío de datos JSON.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN Flutter envía una petición POST al endpoint /api/auth/login THEN el servidor Spring Boot rechaza la petición con error "Content-Type 'text/plain;charset=utf-8' is not supported"

1.2 WHEN Flutter configura el Content-Type en ApiClient THEN el header no se aplica correctamente y se envía como 'text/plain;charset=utf-8'

1.3 WHEN Spring Boot recibe peticiones con Content-Type incorrecto THEN devuelve error 500 Internal Server Error en lugar de procesar la petición JSON

1.4 WHEN se realizan múltiples intentos de login THEN todos fallan con el mismo error de Content-Type, impidiendo la autenticación

### Expected Behavior (Correct)

2.1 WHEN Flutter envía una petición POST al endpoint /api/auth/login THEN el sistema SHALL enviar el Content-Type como 'application/json'

2.2 WHEN Flutter configura el Content-Type en ApiClient THEN el header SHALL aplicarse correctamente a todas las peticiones HTTP

2.3 WHEN Spring Boot recibe peticiones con Content-Type 'application/json' THEN el sistema SHALL procesar correctamente el cuerpo JSON de la petición

2.4 WHEN se realizan peticiones de autenticación con headers correctos THEN el sistema SHALL responder con tokens JWT válidos o errores de autenticación apropiados (401, no 500)

### Unchanged Behavior (Regression Prevention)

3.1 WHEN Flutter envía peticiones GET que no requieren cuerpo JSON THEN el sistema SHALL CONTINUE TO funcionar correctamente sin Content-Type específico

3.2 WHEN Spring Boot recibe peticiones con Content-Type correcto de otros clientes THEN el sistema SHALL CONTINUE TO procesarlas normalmente

3.3 WHEN el sistema maneja errores de autenticación válidos (credenciales incorrectas) THEN el sistema SHALL CONTINUE TO devolver códigos de error apropiados (401, 403)

3.4 WHEN se utilizan otros endpoints que ya funcionan correctamente THEN el sistema SHALL CONTINUE TO mantener su funcionalidad actual