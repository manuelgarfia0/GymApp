# Flutter Gym App Architectural Cleanup Bugfix Design

## Overview

Este documento de diseño aborda múltiples problemas arquitectónicos y de calidad de código en la aplicación Flutter de gimnasio que están causando fallos de API, inconsistencias de autenticación, ineficiencia de memoria y carga de mantenimiento. Los problemas abarcan desde desajustes de contratos de datos, inconsistencias de almacenamiento, problemas de inyección de dependencias, duplicación de código, llamadas API redundantes, violaciones de arquitectura limpia, hasta código de depuración en producción y APIs deprecadas.

La estrategia de corrección se basa en la metodología de condición de bug, donde identificamos las condiciones específicas que desencadenan cada problema (C(X)) y definimos el comportamiento esperado correcto (P(result)) mientras preservamos toda la funcionalidad existente que no está afectada por estos bugs.

## Glossary

- **Bug_Condition (C)**: Las condiciones específicas que desencadenan cada uno de los 8 problemas arquitectónicos identificados
- **Property (P)**: El comportamiento deseado cuando se corrigen estos problemas arquitectónicos
- **Preservation**: La funcionalidad existente de autenticación, navegación, gestión de estado y experiencia de usuario que debe permanecer inalterada
- **ApiClient**: El cliente HTTP en `lib/core/network/api_client.dart` que maneja las peticiones a la API de Spring Boot
- **SecureStorageService**: El servicio en `lib/core/storage/secure_storage_service.dart` que maneja el almacenamiento seguro de tokens JWT
- **DependencyInjection**: El sistema de inyección de dependencias que coordina las instancias de servicios entre módulos
- **Exercise Model**: Los modelos de datos que mapean la información de ejercicios entre la API Java y Flutter
- **Clean Architecture**: El patrón arquitectónico que separa las capas de datos, dominio y presentación

## Bug Details

### Bug Condition

Los bugs se manifiestan en 8 condiciones específicas que afectan diferentes aspectos de la arquitectura de la aplicación:

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type SystemOperation
  OUTPUT: boolean
  
  RETURN (
    // 1. API Contract Mismatch
    (input.operation == "PARSE_EXERCISE_JSON" AND 
     input.jsonFields CONTAINS ["primaryMuscleName", "equipmentName", "secondaryMuscleNames"] AND
     input.expectedFields CONTAINS ["primaryMuscle", "equipment", "secondaryMuscles"]) OR
    
    // 2. Storage Inconsistency  
    (input.operation == "READ_JWT_TOKEN" AND
     input.storageType == "SharedPreferences" AND
     input.actualStorageType == "FlutterSecureStorage") OR
    
    // 3. Multiple ApiClient Instances
    (input.operation == "INITIALIZE_DEPENDENCIES" AND
     input.featureModules.length > 1 AND
     input.apiClientInstances > 1) OR
    
    // 4. Code Duplication
    (input.operation == "LOAD_EXERCISES" AND
     input.screens CONTAINS ["ExercisesScreen", "ExerciseSelectionScreen"] AND
     input.duplicatedLogic == true) OR
    
    // 5. Double API Calls
    (input.operation == "LOGIN_USER" AND
     input.apiCalls CONTAINS ["POST /api/auth/login", "GET /api/auth/me"] AND
     input.redundantCalls == true) OR
    
    // 6. Clean Architecture Violations
    (input.operation == "ACCESS_STORAGE" AND
     input.layer == "DATA_LAYER" AND
     input.directImports CONTAINS ["SharedPreferences"]) OR
    
    // 7. Production Debug Code
    (input.operation == "RENDER_LOGIN_SCREEN" AND
     input.environment == "PRODUCTION" AND
     input.debugElements.length > 0) OR
    
    // 8. Deprecated APIs
    (input.operation == "HANDLE_BACK_NAVIGATION" AND
     input.widget == "WillPopScope" AND
     input.flutterVersion >= "3.12")
  )
END FUNCTION
```

### Examples

- **API Contract Mismatch**: Cuando la API Java envía `{"primaryMuscleName": "Chest", "equipmentName": "Barbell"}` pero Flutter espera `{"primaryMuscle": "Chest", "equipment": "Barbell"}`, causando fallos de parsing
- **Storage Inconsistency**: HomeScreen intenta leer JWT token con `prefs.getString('jwt_token')` pero el token está almacenado en FlutterSecureStorage, retornando siempre null
- **Multiple ApiClient Instances**: AuthDependencies, WorkoutDependencies y ProfileDependencies cada uno crea su propia instancia de ApiClient en lugar de compartir una singleton
- **Code Duplication**: ExercisesScreen y ExerciseSelectionScreen implementan lógica idéntica para carga, búsqueda y manejo de errores de ejercicios
- **Double API Calls**: LoginUser use case ejecuta POST /api/auth/login seguido de GET /api/auth/me redundante en diferentes lugares
- **Clean Architecture Violations**: AuthRepositoryImpl importa directamente SharedPreferences violando la separación de capas
- **Production Debug Code**: LoginScreen muestra botones "Run Network Diagnostics" y "Test Login with Credentials" en producción
- **Deprecated APIs**: ActiveWorkoutScreen usa WillPopScope que está deprecado desde Flutter 3.12+

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Los flujos de autenticación deben continuar manteniendo el almacenamiento seguro de tokens JWT y la validación
- La navegación entre pantallas debe continuar proporcionando transiciones suaves y gestión de estado adecuada
- Las llamadas API con tokens válidos deben continuar autenticándose exitosamente y recibiendo datos
- Los usuarios deben continuar teniendo la misma experiencia de usuario y funcionalidad al interactuar con listas de ejercicios y funcionalidad de workout
- El manejo de errores y estados de carga debe continuar mostrando retroalimentación apropiada a los usuarios
- La inyección de dependencias debe continuar proporcionando gestión adecuada de instancias y ciclo de vida
- Las interacciones entre capas de arquitectura limpia deben continuar manteniendo separación adecuada de responsabilidades y testabilidad
- La aplicación debe continuar funcionando correctamente en plataformas Android e iOS

**Scope:**
Todas las operaciones que NO involucran las 8 condiciones de bug específicas deben permanecer completamente inalteradas por estas correcciones. Esto incluye:
- Interacciones de usuario existentes (clics de mouse, otros inputs de teclado, inputs táctiles)
- Funcionalidad de workout y rutinas que no depende de los componentes bugueados
- Gestión de perfiles de usuario que no involucra los problemas de almacenamiento identificados
- Navegación y transiciones que no usan APIs deprecadas

## Hypothesized Root Cause

Basado en el análisis del código, las causas más probables son:

1. **API Contract Evolution**: La API de Spring Boot evolucionó sus nombres de campos pero los modelos Flutter no se actualizaron
   - Java usa `primaryMuscleName`, `equipmentName`, `secondaryMuscleNames`
   - Flutter espera `primaryMuscle`, `equipment`, `secondaryMuscles`

2. **Storage Service Inconsistency**: Diferentes partes de la aplicación usan diferentes mecanismos de almacenamiento
   - AuthRepository usa correctamente FlutterSecureStorage con clave 'jwt_token'
   - HomeScreen intenta leer desde SharedPreferences con clave 'jwt_token'

3. **Dependency Injection Architecture**: Cada módulo de feature crea sus propias instancias en lugar de usar un contenedor global
   - AuthDependencies.apiClient crea nueva instancia
   - WorkoutDependencies.apiClient crea nueva instancia
   - ProfileDependencies.apiClient crea nueva instancia

4. **Component Abstraction Gap**: Falta de componentes compartidos para funcionalidad común
   - ExercisesScreen y ExerciseSelectionScreen duplican lógica de carga y búsqueda
   - No existe un widget reutilizable ExerciseListComponent

5. **Use Case Orchestration**: LoginUser use case no está optimizado para evitar llamadas redundantes
   - Ejecuta POST /api/auth/login correctamente
   - Luego ejecuta GET /api/auth/me innecesariamente en múltiples lugares

6. **Layer Boundary Violations**: La capa de datos accede directamente a servicios de infraestructura
   - AuthRepositoryImpl importa SharedPreferences directamente
   - Falta abstracción de StorageService en la capa de dominio

7. **Build Configuration**: Código de depuración no está condicionado por environment flags
   - LoginScreen incluye botones de diagnóstico sin verificación de environment
   - Falta configuración de build para remover código debug en producción

8. **Flutter Version Lag**: Uso de APIs deprecadas sin migración a nuevas APIs
   - WillPopScope deprecado desde Flutter 3.12+
   - PopScope es la nueva API recomendada

## Correctness Properties

Property 1: Bug Condition - Architectural Issues Resolution

_For any_ system operation where one of the 8 bug conditions holds (isBugCondition returns true), the fixed system SHALL resolve the specific architectural issue while maintaining all existing functionality, ensuring proper API contract mapping, consistent storage access, singleton dependency injection, shared component usage, optimized API calls, clean architecture compliance, production-ready UI, and modern API usage.

**Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9**

Property 2: Preservation - Non-Affected System Operations

_For any_ system operation where none of the 8 bug conditions hold (isBugCondition returns false), the fixed system SHALL produce exactly the same behavior as the original system, preserving all authentication flows, navigation patterns, user interactions, state management, error handling, and cross-platform functionality.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8**

## Fix Implementation

### Changes Required

Asumiendo que nuestro análisis de causa raíz es correcto:

**File**: `lib/features/workouts/data/models/exercise_model.dart` (New)

**Function**: `ExerciseModel.fromJson`

**Specific Changes**:
1. **API Contract Mapping**: Crear modelo que mapee correctamente los campos de la API Java
   - Mapear `primaryMuscleName` → `primaryMuscle`
   - Mapear `equipmentName` → `equipment`  
   - Mapear `secondaryMuscleNames` → `secondaryMuscles`

2. **JSON Serialization**: Implementar fromJson y toJson con mapeo correcto de campos

**File**: `lib/features/home/screens/home_screen.dart`

**Function**: `_loadUserId`

**Specific Changes**:
3. **Storage Consistency**: Cambiar acceso de almacenamiento para usar el servicio correcto
   - Reemplazar `SharedPreferences` con `SecureStorageService` para acceso a JWT token
   - Mantener `SharedPreferences` solo para `user_id` (no sensible)

**File**: `lib/core/di/global_dependencies.dart` (New)

**Function**: Global dependency container

**Specific Changes**:
4. **Singleton Dependency Injection**: Crear contenedor global de dependencias
   - Implementar singleton ApiClient compartido entre todos los módulos
   - Implementar singleton SecureStorageService compartido
   - Refactorizar feature dependencies para usar instancias globales

**File**: `lib/core/widgets/exercise_list_component.dart` (New)

**Function**: Shared exercise list widget

**Specific Changes**:
5. **Code Deduplication**: Crear componente compartido para funcionalidad de ejercicios
   - Extraer lógica común de carga, búsqueda y manejo de errores
   - Implementar widget reutilizable ExerciseListComponent
   - Refactorizar ExercisesScreen y ExerciseSelectionScreen para usar el componente

**File**: `lib/features/auth/domain/use_cases/login_user.dart`

**Function**: `call` method

**Specific Changes**:
6. **API Call Optimization**: Optimizar flujo de login para eliminar llamadas redundantes
   - Mantener solo POST /api/auth/login
   - Eliminar GET /api/auth/me redundante
   - Obtener información de usuario del token JWT decodificado

**File**: `lib/features/auth/data/repositories/auth_repository_impl.dart`

**Function**: Storage access methods

**Specific Changes**:
7. **Clean Architecture Compliance**: Eliminar violaciones de arquitectura limpia
   - Remover import directo de SharedPreferences
   - Usar solo SecureStorageService inyectado
   - Crear abstracción StorageRepository en capa de dominio si es necesario

**File**: `lib/features/auth/presentation/screens/login_screen.dart`

**Function**: `build` method

**Specific Changes**:
8. **Production Debug Code Removal**: Remover elementos de debug de producción
   - Condicionar botones de diagnóstico con `kDebugMode`
   - Remover mensajes de éxito hardcodeados
   - Limpiar logs de producción

**File**: `lib/features/workouts/presentation/screens/active_workout_screen.dart`

**Function**: `build` method

**Specific Changes**:
9. **Deprecated API Migration**: Migrar de APIs deprecadas a APIs modernas
   - Reemplazar `WillPopScope` con `PopScope`
   - Actualizar parámetros y callbacks según nueva API
   - Mantener funcionalidad idéntica de navegación hacia atrás

## Testing Strategy

### Validation Approach

La estrategia de testing sigue un enfoque de dos fases: primero, identificar contraejemplos que demuestren los bugs en código sin corregir, luego verificar que las correcciones funcionan correctamente y preservan el comportamiento existente.

### Exploratory Bug Condition Checking

**Goal**: Identificar contraejemplos que demuestren los 8 bugs ANTES de implementar las correcciones. Confirmar o refutar el análisis de causa raíz. Si refutamos, necesitaremos re-hipotetizar.

**Test Plan**: Escribir tests que simulen cada una de las 8 condiciones de bug y verificar que fallan en el código SIN CORREGIR para observar los fallos y entender las causas raíz.

**Test Cases**:
1. **API Contract Mismatch Test**: Simular respuesta JSON de Spring Boot con campos `primaryMuscleName`, `equipmentName`, `secondaryMuscleNames` y verificar que el parsing falla (fallará en código sin corregir)
2. **Storage Inconsistency Test**: Simular lectura de JWT token desde SharedPreferences cuando está almacenado en SecureStorage y verificar que retorna null (fallará en código sin corregir)
3. **Multiple ApiClient Test**: Verificar que AuthDependencies, WorkoutDependencies y ProfileDependencies crean instancias separadas de ApiClient (fallará en código sin corregir)
4. **Code Duplication Test**: Verificar que ExercisesScreen y ExerciseSelectionScreen contienen lógica duplicada para manejo de ejercicios (fallará en código sin corregir)
5. **Double API Calls Test**: Monitorear llamadas de red durante login y verificar que se hacen múltiples llamadas redundantes (fallará en código sin corregir)
6. **Architecture Violation Test**: Verificar que AuthRepositoryImpl importa directamente SharedPreferences violando clean architecture (fallará en código sin corregir)
7. **Production Debug Code Test**: Verificar que LoginScreen muestra elementos de debug en build de producción (fallará en código sin corregir)
8. **Deprecated API Test**: Verificar que ActiveWorkoutScreen usa WillPopScope en Flutter 3.12+ (fallará en código sin corregir)

**Expected Counterexamples**:
- Fallos de parsing JSON por desajuste de nombres de campos
- Valores null al intentar leer tokens desde almacenamiento incorrecto
- Múltiples instancias de ApiClient creadas innecesariamente
- Lógica duplicada en múltiples screens de ejercicios
- Llamadas API redundantes durante el proceso de login
- Imports directos de infraestructura en capa de datos
- Elementos de UI de debug visibles en producción
- Warnings de deprecación por uso de APIs obsoletas

### Fix Checking

**Goal**: Verificar que para todas las operaciones donde las condiciones de bug se mantienen, el sistema corregido produce el comportamiento esperado.

**Pseudocode:**
```
FOR ALL operation WHERE isBugCondition(operation) DO
  result := fixedSystem(operation)
  ASSERT expectedBehavior(result)
END FOR
```

### Preservation Checking

**Goal**: Verificar que para todas las operaciones donde las condiciones de bug NO se mantienen, el sistema corregido produce el mismo resultado que el sistema original.

**Pseudocode:**
```
FOR ALL operation WHERE NOT isBugCondition(operation) DO
  ASSERT originalSystem(operation) = fixedSystem(operation)
END FOR
```

**Testing Approach**: Se recomienda property-based testing para preservation checking porque:
- Genera muchos casos de prueba automáticamente a través del dominio de entrada
- Captura casos edge que los unit tests manuales podrían perder
- Proporciona garantías sólidas de que el comportamiento permanece inalterado para todas las operaciones no afectadas por bugs

**Test Plan**: Observar comportamiento en código SIN CORREGIR primero para operaciones no afectadas por bugs, luego escribir property-based tests que capturen ese comportamiento.

**Test Cases**:
1. **Authentication Flow Preservation**: Observar que los flujos de autenticación funcionan correctamente en código sin corregir, luego escribir tests para verificar que continúan funcionando después de las correcciones
2. **Navigation Preservation**: Observar que la navegación entre pantallas funciona correctamente en código sin corregir, luego escribir tests para verificar que continúa funcionando después de las correcciones
3. **User Interaction Preservation**: Observar que las interacciones de usuario (clics, inputs) funcionan correctamente en código sin corregir, luego escribir tests para verificar que continúan funcionando después de las correcciones
4. **State Management Preservation**: Observar que la gestión de estado funciona correctamente en código sin corregir, luego escribir tests para verificar que continúa funcionando después de las correcciones

### Unit Tests

- Test de mapeo de campos JSON para modelos de Exercise con datos de Spring Boot
- Test de acceso consistente a almacenamiento para tokens JWT y datos de usuario
- Test de inyección de dependencias singleton para ApiClient y servicios compartidos
- Test de componentes compartidos para funcionalidad de ejercicios
- Test de optimización de llamadas API durante proceso de login
- Test de cumplimiento de clean architecture en capas de datos
- Test de remoción de código de debug en builds de producción
- Test de migración de APIs deprecadas a APIs modernas

### Property-Based Tests

- Generar estados aleatorios de aplicación y verificar que el mapeo de API funciona correctamente
- Generar configuraciones aleatorias de dependencias y verificar que se usan instancias singleton
- Generar interacciones aleatorias de usuario y verificar que la funcionalidad preservada continúa funcionando
- Test que todas las operaciones no afectadas por bugs continúan funcionando a través de muchos escenarios

### Integration Tests

- Test de flujo completo de aplicación con correcciones arquitectónicas aplicadas
- Test de integración entre módulos usando dependencias singleton compartidas
- Test de que la funcionalidad de ejercicios funciona correctamente con componentes compartidos
- Test de que los flujos de autenticación funcionan con almacenamiento consistente
- Test de que la aplicación funciona correctamente en Android e iOS después de las correcciones