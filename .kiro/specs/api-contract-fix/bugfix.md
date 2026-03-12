# Bugfix Requirements Document

## Introduction

Basado en el análisis de los logs de Spring Boot, el sistema presenta problemas específicos de sincronización de contratos entre GymApp (Flutter) y GymAPI (Spring Boot). Los logs revelan que algunos problemas inicialmente identificados ya están funcionando correctamente, mientras que otros requieren atención:

**Problemas confirmados por los logs:**

1. **Content-Type ya funciona**: Los logs confirman que Spring Boot está recibiendo y procesando correctamente "application/json;charset=UTF-8" en las peticiones POST de login.

2. **Problema de credenciales de prueba**: Los logs muestran que el usuario "manuel" existe pero la contraseña no coincide con la almacenada en la base de datos.

3. **Null Safety crítico**: Los logs de consultas SQL revelan campos que pueden ser nulos en PostgreSQL (`created_at`, `language_preference`, `is_premium`) pero Flutter espera valores no anulables, causando crashes de deserialización.

4. **Manejo correcto de errores de autenticación**: Spring Boot devuelve correctamente HTTP 401 UNAUTHORIZED para credenciales inválidas, no errores 500.

## Bug Analysis

### Current Behavior (Defect)

**Credenciales de Prueba:**

1.1 WHEN se intenta autenticar con las credenciales manuel/mypassword123 THEN el sistema falla porque la contraseña no coincide con la almacenada en la base de datos

**Null Safety Issues (Confirmados por logs SQL):**

1.2 WHEN el backend Java envía campos nulos para `created_at` en UserDTO THEN Flutter falla al deserializar porque UserDto.fromJson() espera DateTime no anulable

1.3 WHEN el backend Java envía campos nulos para `language_preference` en UserDTO THEN Flutter falla al deserializar porque UserDto.fromJson() espera String no anulable

1.4 WHEN el backend Java envía campos nulos para `is_premium` en UserDTO THEN Flutter falla al deserializar porque UserDto.fromJson() espera bool no anulable

1.5 WHEN el backend Java envía campos nulos en otros DTOs (ExerciseDTO, RoutineDTO, WorkoutDTO) THEN Flutter falla al deserializar porque los modelos Dart esperan valores no anulables

1.6 WHEN se realizan peticiones de autenticación exitosas pero con campos nulos en la respuesta THEN la aplicación crash durante la deserialización del UserDTO

### Expected Behavior (Correct)

**Credenciales de Prueba:**

2.1 WHEN se intenta autenticar con credenciales válidas THEN el sistema SHALL autenticar correctamente y devolver un token JWT válido

**Null Safety Fixes (Basado en esquema SQL identificado):**

2.2 WHEN el backend Java envía campos nulos para `created_at` en UserDTO THEN Flutter SHALL deserializar correctamente manejando el campo como DateTime? opcional

2.3 WHEN el backend Java envía campos nulos para `language_preference` en UserDTO THEN Flutter SHALL deserializar correctamente manejando el campo como String? opcional

2.4 WHEN el backend Java envía campos nulos para `is_premium` en UserDTO THEN Flutter SHALL deserializar correctamente manejando el campo como bool? opcional

2.5 WHEN el backend Java envía campos nulos en otros DTOs THEN Flutter SHALL deserializar correctamente todos los campos opcionales identificados en el esquema de base de datos

2.6 WHEN se realizan peticiones de autenticación exitosas con campos nulos en la respuesta THEN la aplicación SHALL deserializar correctamente y mostrar la interfaz de usuario apropiada

### Unchanged Behavior (Regression Prevention)

**HTTP Communication (Ya funcionando correctamente según logs):**

3.1 WHEN Flutter envía peticiones POST con Content-Type "application/json;charset=UTF-8" THEN el sistema SHALL CONTINUE TO procesarlas correctamente como lo hace actualmente

3.2 WHEN Spring Boot recibe peticiones con Content-Type correcto THEN el sistema SHALL CONTINUE TO procesarlas y devolver respuestas apropiadas

3.3 WHEN el sistema maneja errores de autenticación válidos (credenciales incorrectas) THEN el sistema SHALL CONTINUE TO devolver HTTP 401 UNAUTHORIZED como lo hace actualmente

**Data Serialization:**

3.4 WHEN el backend Java envía campos no nulos en respuestas JSON THEN Flutter SHALL CONTINUE TO deserializar correctamente todos los campos requeridos

3.5 WHEN Flutter envía peticiones con datos válidos al backend THEN el sistema SHALL CONTINUE TO procesar y persistir la información correctamente

3.6 WHEN se utilizan endpoints que ya funcionan correctamente con datos completos THEN el sistema SHALL CONTINUE TO mantener su funcionalidad actual

**Database Operations (Confirmado por logs SQL):**

3.7 WHEN se ejecutan consultas SQL para autenticación THEN el sistema SHALL CONTINUE TO ejecutar correctamente las consultas como "select u1_0.id,u1_0.created_at,u1_0.email,u1_0.is_premium,u1_0.language_preference,u1_0.password,u1_0.public_profile,u1_0.username from users u1_0 where u1_0.username=?"