# Plan de Implementación - Sincronización de Contratos Null Safety

## Análisis de DTOs Identificados

Después de revisar los DTOs existentes, se identificaron los siguientes problemas potenciales:

**UserDto (auth)**: ✅ Ya maneja null safety correctamente
- `createdAt`: String? (correcto)
- `languagePreference`: String? (correcto) 
- `isPremium`: bool con fallback a false (correcto)

**UserProfileDto (profile)**: ⚠️ Problemas identificados
- Usa fallbacks con `??` pero puede enmascarar problemas reales
- `premium` vs `isPremium` inconsistencia de naming

**ExerciseDto (workouts)**: ⚠️ Campos potencialmente problemáticos
- `description`: String (no anulable, puede ser problemático)
- Todos los campos definidos como requeridos

**RoutineDto/WorkoutDto (workouts)**: ⚠️ Campos de timestamp problemáticos
- Varios campos String para timestamps que pueden ser nulos

---

## Tareas de Implementación

- [x] 1. Escribir test de exploración de bug condition
  - **Property 1: Bug Condition** - Deserialización con Campos Nulos Críticos
  - **CRÍTICO**: Este test DEBE FALLAR en código sin corregir - el fallo confirma que el bug existe
  - **NO intentar corregir el test o el código cuando falle**
  - **NOTA**: Este test codifica el comportamiento esperado - validará la corrección cuando pase después de la implementación
  - **OBJETIVO**: Generar contraejemplos que demuestren el bug existe
  - **Enfoque PBT Acotado**: Para bugs determinísticos, acotar la propiedad a los casos concretos que fallan para asegurar reproducibilidad
  - Probar deserialización de ExerciseDto con `description: null` (debe fallar en código sin corregir)
  - Probar deserialización de UserProfileDto con campos requeridos nulos usando fallbacks incorrectos
  - Probar deserialización de RoutineDto/WorkoutDto con timestamps nulos en campos no anulables
  - Las aserciones del test deben coincidir con las Propiedades de Comportamiento Esperado del diseño
  - Ejecutar test en código SIN CORREGIR
  - **RESULTADO ESPERADO**: Test FALLA (esto es correcto - prueba que el bug existe)
  - Documentar contraejemplos encontrados para entender la causa raíz
  - Marcar tarea como completa cuando el test esté escrito, ejecutado y el fallo documentado
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 2. Escribir tests de preservación de propiedades (ANTES de implementar corrección)
  - **Property 2: Preservation** - Comportamiento de Deserialización con Datos Completos
  - **IMPORTANTE**: Seguir metodología observation-first
  - Observar comportamiento en código SIN CORREGIR para entradas no buggy
  - Escribir property-based tests capturando patrones de comportamiento observados de Preservation Requirements
  - Property-based testing genera muchos casos de prueba para garantías más fuertes
  - Ejecutar tests en código SIN CORREGIR
  - **RESULTADO ESPERADO**: Tests PASAN (esto confirma comportamiento baseline a preservar)
  - Marcar tarea como completa cuando tests estén escritos, ejecutados y pasando en código sin corregir
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 3. Corrección para sincronización de contratos null safety

  - [x] 3.1 Auditar y corregir ExerciseDto
    - Cambiar `description` de `String` a `String?` para manejar valores nulos
    - Actualizar método `fromJson()` para manejar description nula apropiadamente
    - Actualizar entity Exercise correspondiente para consistencia
    - Verificar que otros campos opcionales estén correctamente tipados
    - _Bug_Condition: isBugCondition(input) donde input contiene campos nulos críticos_
    - _Expected_Behavior: expectedBehavior(result) deserialización exitosa sin crashes_
    - _Preservation: Preservation Requirements - comportamiento inalterado para datos completos_
    - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2_

  - [x] 3.2 Corregir inconsistencias en UserProfileDto
    - Eliminar fallbacks con `??` que enmascaran problemas reales
    - Cambiar campos requeridos a opcionales donde sea apropiado según esquema de BD
    - Estandarizar naming: usar `isPremium` consistentemente
    - Actualizar entity UserProfile para reflejar opcionalidad correcta
    - _Bug_Condition: isBugCondition(input) donde fallbacks enmascaran nulos legítimos_
    - _Expected_Behavior: expectedBehavior(result) manejo explícito de nulos_
    - _Preservation: Preservation Requirements - funcionalidad existente para datos válidos_
    - _Requirements: 2.4, 2.5, 3.3, 3.4_

  - [x] 3.3 Corregir campos de timestamp en RoutineDto y WorkoutDto
    - Verificar que campos de timestamp opcionales estén correctamente tipados como String?
    - Actualizar métodos `fromJson()` para manejar timestamps nulos sin crashes
    - Verificar conversión a DateTime en métodos `toEntity()` con manejo de nulos
    - Actualizar entities correspondientes para consistencia
    - _Bug_Condition: isBugCondition(input) donde timestamps son nulos_
    - _Expected_Behavior: expectedBehavior(result) conversión segura de timestamps_
    - _Preservation: Preservation Requirements - conversión correcta para timestamps válidos_
    - _Requirements: 2.3, 2.5, 3.5_

  - [x] 3.4 Verificar test de exploración de bug condition ahora pasa
    - **Property 1: Expected Behavior** - Deserialización Robusta con Campos Nulos Críticos
    - **IMPORTANTE**: Re-ejecutar el MISMO test de la tarea 1 - NO escribir un test nuevo
    - El test de la tarea 1 codifica el comportamiento esperado
    - Cuando este test pase, confirma que el comportamiento esperado se satisface
    - Ejecutar test de exploración de bug condition del paso 1
    - **RESULTADO ESPERADO**: Test PASA (confirma que el bug está corregido)
    - _Requirements: Propiedades de Comportamiento Esperado del diseño_

  - [x] 3.5 Verificar que tests de preservación aún pasan
    - **Property 2: Preservation** - Comportamiento de Deserialización con Datos Completos
    - **IMPORTANTE**: Re-ejecutar los MISMOS tests de la tarea 2 - NO escribir tests nuevos
    - Ejecutar property-based tests de preservación del paso 2
    - **RESULTADO ESPERADO**: Tests PASAN (confirma que no hay regresiones)
    - Confirmar que todos los tests aún pasan después de la corrección (sin regresiones)

- [x] 4. Checkpoint - Asegurar que todos los tests pasan
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.