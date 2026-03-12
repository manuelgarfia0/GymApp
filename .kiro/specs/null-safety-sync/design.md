# Sincronización de Contratos Null Safety Bugfix Design

## Overview

El sistema presenta errores críticos de sincronización de contratos entre la aplicación Flutter y la API Spring Boot relacionados con null safety. Los logs de Spring Boot revelan que campos específicos (`created_at`, `language_preference`, `is_premium`) pueden ser nulos en PostgreSQL pero causan crashes de deserialización en Flutter cuando los DTOs esperan valores no anulables. La solución requiere actualizar todos los modelos Dart para manejar correctamente la opcionalidad de campos según el esquema real de la base de datos, manteniendo la separación entre DTOs (data layer) y entities (domain layer).

## Glossary

- **Bug_Condition (C)**: La condición que activa el bug - cuando Spring Boot envía campos nulos en respuestas JSON pero Flutter espera valores no anulables
- **Property (P)**: El comportamiento deseado cuando se reciben campos nulos - deserialización exitosa sin crashes
- **Preservation**: El comportamiento existente de deserialización de campos no nulos que debe mantenerse sin cambios
- **UserDto**: El DTO en `lib/features/auth/data/models/user_dto.dart` que maneja la serialización JSON del usuario
- **Null Safety**: El sistema de tipos de Dart que distingue entre tipos anulables (T?) y no anulables (T)
- **fromJson**: Los métodos de deserialización que convierten JSON de la API a objetos Dart
- **Schema Mismatch**: La discrepancia entre lo que la base de datos permite (nulos) y lo que Flutter espera (no nulos)

## Bug Details

### Bug Condition

El bug se manifiesta cuando Spring Boot envía respuestas JSON con campos nulos para `created_at`, `language_preference`, `is_premium` y potencialmente otros campos en UserDTO y otros DTOs. Los métodos `fromJson()` de Flutter fallan al intentar deserializar estos campos porque están definidos como no anulables en los modelos Dart, causando crashes de la aplicación.

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type JsonResponse
  OUTPUT: boolean
  
  RETURN input.containsNullFields(['created_at', 'language_preference', 'is_premium'])
         AND dartModel.expectsNonNullable(input.nullFields)
         AND input.fromBackendDatabase == true
END FUNCTION
```

### Examples

- **UserDTO con created_at nulo**: JSON `{"id": 1, "username": "manuel", "created_at": null}` causa crash en `UserDto.fromJson()` porque `createdAt` se define como `String` no anulable
- **UserDTO con language_preference nulo**: JSON con `"language_preference": null` causa crash porque el modelo espera `String` no anulable  
- **UserDTO con is_premium nulo**: JSON con `"is_premium": null` causa crash porque el modelo espera `bool` no anulable
- **Otros DTOs**: ExerciseDTO, RoutineDTO, WorkoutDTO pueden tener campos similares que causan crashes
- **Autenticación exitosa**: Login correcto pero crash durante deserialización de la respuesta del usuario

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Deserialización de campos no nulos debe continuar funcionando exactamente como antes
- Conversión de DTOs a entities del dominio debe mantenerse sin cambios para campos válidos
- Métodos `toJson()` para envío de datos al backend deben permanecer inalterados
- Separación entre data layer (DTOs) y domain layer (entities) debe preservarse
- Funcionalidad existente para campos requeridos debe continuar funcionando

**Scope:**
Todas las operaciones que NO involucran campos nulos de la base de datos deben ser completamente inalteradas por esta corrección. Esto incluye:
- Deserialización de respuestas JSON con todos los campos poblados
- Serialización de objetos Dart a JSON para peticiones
- Conversión entre DTOs y entities para datos completos
- Validación y lógica de negocio existente
## Hypothesized Root Cause

Basado en la descripción del bug y el análisis de los logs de Spring Boot, las causas más probables son:

1. **Discrepancia de Esquema de Base de Datos**: Los campos en PostgreSQL están definidos como anulables pero los DTOs Dart los definen como requeridos
   - `created_at` puede ser NULL en la tabla users pero UserDto.createdAt es String no anulable
   - `language_preference` puede ser NULL pero se define como String requerido
   - `is_premium` puede ser NULL pero se define como bool requerido

2. **Definición Incorrecta de Tipos en DTOs**: Los modelos Dart no reflejan la opcionalidad real del esquema de base de datos
   - Campos opcionales definidos como requeridos en constructores
   - Métodos fromJson() que no manejan valores nulos apropiadamente

3. **Falta de Validación de Contratos**: No hay proceso sistemático para verificar que los contratos entre backend y frontend estén sincronizados
   - Cambios en el esquema de base de datos no se reflejan en los DTOs
   - No hay tests que validen la deserialización con campos nulos

4. **Inconsistencia en Otros DTOs**: El problema puede extenderse más allá de UserDTO a otros modelos como ExerciseDTO, RoutineDTO, WorkoutDTO
   - Campos de timestamp, descripción, notas pueden ser anulables en la base de datos
   - Misma discrepancia entre esquema real y definición de DTOs

## Correctness Properties

Property 1: Bug Condition - Deserialización Robusta con Campos Nulos

_Para cualquier_ respuesta JSON del backend Spring Boot que contenga campos nulos para `created_at`, `language_preference`, `is_premium` u otros campos opcionales, los métodos `fromJson()` corregidos DEBERÁN deserializar exitosamente sin crashes, manejando los valores nulos apropiadamente según la opcionalidad real del esquema de base de datos.

**Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5**

Property 2: Preservation - Deserialización de Campos No Nulos

_Para cualquier_ respuesta JSON del backend que contenga todos los campos poblados (sin nulos), los DTOs corregidos DEBERÁN producir exactamente el mismo resultado que los DTOs originales, preservando toda la funcionalidad existente para datos completos y manteniendo la separación entre data layer y domain layer.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5**

## Fix Implementation

### Changes Required

Asumiendo que nuestro análisis de causa raíz es correcto:

**Files**: Múltiples archivos de DTOs en las capas de datos de cada feature

**Primary Changes**:

1. **UserDto Null Safety Fix**: Actualizar `lib/features/auth/data/models/user_dto.dart`
   - Cambiar `createdAt` de `String` a `String?` para manejar valores nulos
   - Verificar que `languagePreference` ya es `String?` (parece correcto)
   - Verificar que `isPremium` maneja correctamente valores nulos con fallback a `false`
   - Actualizar método `fromJson()` para manejar todos los campos nulos apropiadamente

2. **Auditoría de Otros DTOs**: Revisar y actualizar otros modelos de datos
   - `ExerciseDto`: Verificar campos como `description` que pueden ser opcionales
   - `RoutineDto`: Verificar campos como `createdAt`, `description` 
   - `WorkoutDto`: Verificar campos de timestamp y opcionales
   - Actualizar todos los métodos `fromJson()` para manejar nulos

3. **Sincronización de Entities del Dominio**: Asegurar que las entities reflejen la opcionalidad correcta
   - Actualizar `User` entity para que coincida con la opcionalidad de UserDto
   - Verificar otras entities del dominio para consistencia
   - Mantener la separación clara entre DTOs (serialización) y entities (lógica de negocio)

4. **Validación de Contratos**: Implementar proceso para mantener sincronización
   - Crear tests que validen deserialización con campos nulos
   - Documentar qué campos son opcionales vs requeridos
   - Establecer proceso para actualizar DTOs cuando cambie el esquema de base de datos

5. **Manejo Robusto de Errores**: Mejorar la deserialización para ser más resiliente
   - Agregar valores por defecto apropiados para campos opcionales
   - Mejorar logging para identificar problemas de deserialización
   - Implementar fallbacks seguros para campos críticos
## Testing Strategy

### Validation Approach

La estrategia de testing sigue un enfoque de dos fases: primero, generar contraejemplos que demuestren el bug en código sin corregir, luego verificar que la corrección funciona correctamente y preserva el comportamiento existente.

### Exploratory Bug Condition Checking

**Goal**: Generar contraejemplos que demuestren el bug ANTES de implementar la corrección. Confirmar o refutar el análisis de causa raíz. Si refutamos, necesitaremos re-hipotetizar.

**Test Plan**: Escribir tests que simulen respuestas JSON del backend con campos nulos y verificar que los métodos `fromJson()` actuales fallan. Ejecutar estos tests en el código SIN CORREGIR para observar los crashes y entender la causa raíz.

**Test Cases**:
1. **UserDTO con created_at nulo**: Simular JSON con `"created_at": null` y verificar crash en `UserDto.fromJson()` (fallará en código sin corregir)
2. **UserDTO con language_preference nulo**: Simular JSON con `"language_preference": null` (puede ya funcionar si está como String?)
3. **UserDTO con is_premium nulo**: Simular JSON con `"is_premium": null` y verificar manejo (puede ya tener fallback)
4. **Otros DTOs con campos nulos**: Probar ExerciseDto, RoutineDto, WorkoutDto con campos opcionales nulos (pueden fallar en código sin corregir)

**Expected Counterexamples**:
- Crashes de deserialización cuando campos requeridos son nulos
- Posibles causas: tipos no anulables definidos incorrectamente, falta de manejo de nulos en fromJson()

### Fix Checking

**Goal**: Verificar que para todas las entradas donde se cumple la condición del bug, la función corregida produce el comportamiento esperado.

**Pseudocode:**
```
FOR ALL input WHERE isBugCondition(input) DO
  result := dtoFixed.fromJson(input.jsonWithNulls)
  ASSERT result != null (no crash)
  ASSERT result.handleNullFieldsCorrectly()
  ASSERT result.toEntity() != null (conversion works)
END FOR
```

### Preservation Checking

**Goal**: Verificar que para todas las entradas donde NO se cumple la condición del bug, la función corregida produce el mismo resultado que la función original.

**Pseudocode:**
```
FOR ALL input WHERE NOT isBugCondition(input) DO
  ASSERT dtoOriginal.fromJson(input) = dtoFixed.fromJson(input)
  ASSERT dtoOriginal.toEntity() = dtoFixed.toEntity()
END FOR
```

**Testing Approach**: Se recomienda property-based testing para preservation checking porque:
- Genera muchos casos de prueba automáticamente a través del dominio de entrada
- Detecta casos edge que los unit tests manuales podrían pasar por alto
- Proporciona garantías sólidas de que el comportamiento no cambia para todas las entradas no buggy

**Test Plan**: Observar comportamiento en código SIN CORREGIR primero para respuestas JSON completas, luego escribir property-based tests capturando ese comportamiento.

**Test Cases**:
1. **Preservación de Deserialización Completa**: Verificar que JSONs con todos los campos poblados continúan funcionando
2. **Preservación de Conversión a Entity**: Verificar que `toEntity()` produce los mismos resultados
3. **Preservación de Serialización**: Verificar que `toJson()` continúa funcionando igual
4. **Preservación de Lógica de Negocio**: Verificar que las entities del dominio mantienen su comportamiento

### Unit Tests

- Test deserialización de UserDto con cada campo nulo individualmente
- Test deserialización de otros DTOs con campos opcionales nulos
- Test conversión de DTOs a entities con campos nulos
- Test casos edge (JSONs malformados, tipos incorrectos)
- Test que campos requeridos aún fallan apropiadamente cuando son nulos

### Property-Based Tests

- Generar JSONs aleatorios con combinaciones de campos nulos y verificar deserialización exitosa
- Generar configuraciones aleatorias de datos completos y verificar preservación del comportamiento
- Test que todos los flujos de autenticación funcionan correctamente a través de muchos escenarios
- Verificar que la conversión DTO->Entity->DTO es consistente

### Integration Tests

- Test flujo completo de login con respuesta que contiene campos nulos
- Test flujo de registro y manejo de usuarios con datos parciales
- Test que la interfaz de usuario maneja correctamente usuarios con campos opcionales nulos
- Test que las operaciones CRUD funcionan con datos parciales del backend
- Test switching entre contextos de UI con datos de usuario incompletos