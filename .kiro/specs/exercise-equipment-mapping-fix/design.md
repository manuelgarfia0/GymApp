# Exercise Equipment Mapping Fix Bugfix Design

## Overview

El análisis del código revela que el mapeo de campos entre el backend Spring Boot y el frontend Flutter ya ha sido parcialmente corregido. El ExerciseDto actualmente mapea el campo "category" en lugar de "equipment", pero persiste la discrepancia reportada donde el campo equipment aparece como null en la UI. Este diseño establece un enfoque sistemático para investigar la estructura real de la respuesta de la API, verificar el mapeo correcto y asegurar que la información del equipo se muestre correctamente en la interfaz de usuario.

## Glossary

- **Bug_Condition (C)**: La condición que desencadena el bug - cuando el campo equipment/category aparece como null en la UI a pesar de tener datos válidos en el backend
- **Property (P)**: El comportamiento deseado cuando se cargan ejercicios - el campo equipment/category debe mostrarse correctamente con el valor de la base de datos
- **Preservation**: El comportamiento existente de mapeo de otros campos (name, description, etc.) que debe permanecer inalterado
- **ExerciseDto**: El Data Transfer Object en `lib/features/workouts/data/models/exercise_dto.dart` que maneja la serialización JSON con el backend Spring Boot
- **Exercise**: La entidad del dominio en `lib/features/workouts/domain/entities/exercise.dart` que representa el concepto de negocio
- **category**: El campo actual en el DTO que mapea la información del equipo desde el backend

## Bug Details

### Bug Condition

El bug se manifiesta cuando la aplicación Flutter solicita ejercicios desde la API Spring Boot y el campo equipment aparece como null en la UI, a pesar de que otros campos como description se muestran correctamente. El ExerciseDto.fromJson() actualmente mapea el campo "category" del JSON, pero existe una discrepancia entre lo que el backend envía ("equipment") y lo que el frontend espera ("category").

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type ExerciseApiResponse
  OUTPUT: boolean
  
  RETURN input.containsField('equipment') 
         AND input.equipment IS NOT NULL
         AND mappedExercise.category IS NULL
         AND otherFieldsMapCorrectly(input)
END FUNCTION
```

### Examples

- **Caso 1**: API envía `{"id": 1, "name": "Bench Press", "equipment": "Barbell", "description": "Chest exercise"}` → UI muestra equipment como null pero description correctamente
- **Caso 2**: API envía `{"id": 2, "name": "Squat", "equipment": "Barbell", "description": "Leg exercise"}` → UI muestra equipment como null pero description correctamente  
- **Caso 3**: API envía `{"id": 3, "name": "Push-up", "equipment": "Bodyweight", "description": "Bodyweight exercise"}` → UI muestra equipment como null pero description correctamente
- **Edge case**: API envía campo "category" en lugar de "equipment" → mapeo funciona correctamente

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- El mapeo de campos name, description, primaryMuscle y secondaryMuscles debe continuar funcionando exactamente como antes
- La conversión de DTO a entidad del dominio debe mantener la separación limpia entre capas
- Las operaciones de búsqueda y filtrado de ejercicios deben continuar funcionando sin afectación

**Scope:**
Todas las operaciones que NO involucran el campo equipment/category deben permanecer completamente inalteradas por esta corrección. Esto incluye:
- Carga y visualización de otros campos de ejercicios
- Operaciones CRUD de rutinas y workouts
- Autenticación y navegación de la aplicación

## Hypothesized Root Cause

Basado en el análisis del código y la descripción del bug, las causas más probables son:

1. **Discrepancia de Nombres de Campo**: El backend Spring Boot envía "equipment" pero el ExerciseDto mapea "category"
   - El fromJson() busca json['category'] cuando debería buscar json['equipment']
   - O el backend cambió para enviar "equipment" pero el frontend no se actualizó

2. **Inconsistencia en la API**: El backend puede estar enviando diferentes nombres de campo en diferentes endpoints
   - Algunos endpoints envían "equipment", otros "category"
   - Falta de estandarización en la respuesta de la API

3. **Problema de Serialización**: El backend puede no estar incluyendo el campo en la respuesta JSON
   - Campo marcado como @JsonIgnore accidentalmente
   - Problema en la configuración de Jackson en Spring Boot

4. **Mapeo Incorrecto en el DTO**: El ExerciseDto puede tener lógica de mapeo incorrecta
   - Condición que causa que el campo se mapee como null
   - Problema en la conversión de tipos de datos

## Correctness Properties

Property 1: Bug Condition - Equipment Field Mapping

_For any_ API response where the equipment field is present and not null in the JSON, the fixed ExerciseDto.fromJson() SHALL correctly map the field to the category property, ensuring that equipment information is displayed in the UI.

**Validates: Requirements 2.1, 2.2**

Property 2: Preservation - Other Field Mapping

_For any_ API response containing exercise data, the fixed code SHALL produce exactly the same mapping behavior for all fields except equipment/category (name, description, primaryMuscle, secondaryMuscles), preserving existing functionality for non-equipment related data.

**Validates: Requirements 3.1, 3.2, 3.3**

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct:

**File**: `lib/features/workouts/data/models/exercise_dto.dart`

**Function**: `ExerciseDto.fromJson()`

**Specific Changes**:
1. **API Response Investigation**: Agregar logging temporal para capturar la estructura exacta de la respuesta JSON
   - Imprimir el JSON completo recibido del backend
   - Verificar qué campos están presentes y sus valores

2. **Field Mapping Correction**: Actualizar el mapeo de campos según la estructura real de la API
   - Si el backend envía "equipment": mapear json['equipment'] en lugar de json['category']
   - Si el backend envía "category": mantener el mapeo actual pero verificar la lógica

3. **Fallback Strategy**: Implementar mapeo que soporte ambos nombres de campo
   - Intentar mapear json['equipment'] primero, luego json['category'] como fallback
   - Asegurar compatibilidad con diferentes versiones de la API

4. **Validation Logic**: Agregar validación para detectar campos faltantes
   - Logging cuando el campo esperado no está presente
   - Manejo graceful de respuestas incompletas

5. **Documentation Update**: Actualizar comentarios para reflejar el mapeo correcto
   - Documentar qué campo del backend se mapea a qué propiedad del DTO
   - Explicar la estrategia de fallback si aplica

## Testing Strategy

### Validation Approach

La estrategia de testing sigue un enfoque de dos fases: primero, investigar la estructura real de la respuesta de la API para confirmar o refutar el análisis de causa raíz, luego verificar que la corrección funciona correctamente y preserva el comportamiento existente.

### Exploratory Bug Condition Checking

**Goal**: Investigar la estructura real de la respuesta de la API ANTES de implementar la corrección. Confirmar o refutar el análisis de causa raíz. Si refutamos, necesitaremos re-hipotetizar.

**Test Plan**: Escribir tests que capturen y analicen las respuestas reales de la API Spring Boot. Ejecutar estos tests en el código SIN CORREGIR para observar la estructura exacta del JSON y entender la causa raíz.

**Test Cases**:
1. **API Response Structure Test**: Capturar respuesta real de /api/exercises y analizar campos presentes (fallará en código sin corregir si el campo no se mapea)
2. **Field Presence Test**: Verificar si el backend envía "equipment", "category", o ambos (fallará en código sin corregir si hay discrepancia)
3. **Data Type Test**: Verificar el tipo de datos del campo equipment/category (fallará en código sin corregir si hay problema de tipos)
4. **Multiple Exercises Test**: Verificar consistencia del campo a través de múltiples ejercicios (fallará en código sin corregir si hay inconsistencias)

**Expected Counterexamples**:
- El campo equipment aparece como null en el DTO a pesar de estar presente en el JSON
- Posibles causas: mapeo incorrecto de nombres de campo, problema de serialización, inconsistencia en la API

### Fix Checking

**Goal**: Verificar que para todas las respuestas de API donde la condición de bug se cumple, la función corregida produce el comportamiento esperado.

**Pseudocode:**
```
FOR ALL apiResponse WHERE isBugCondition(apiResponse) DO
  result := ExerciseDto.fromJson_fixed(apiResponse)
  ASSERT expectedBehavior(result)
END FOR
```

### Preservation Checking

**Goal**: Verificar que para todas las respuestas de API donde la condición de bug NO se cumple, la función corregida produce el mismo resultado que la función original.

**Pseudocode:**
```
FOR ALL apiResponse WHERE NOT isBugCondition(apiResponse) DO
  ASSERT ExerciseDto.fromJson_original(apiResponse) = ExerciseDto.fromJson_fixed(apiResponse)
END FOR
```

**Testing Approach**: Property-based testing es recomendado para preservation checking porque:
- Genera muchos casos de prueba automáticamente a través del dominio de entrada
- Detecta casos edge que los unit tests manuales podrían pasar por alto
- Proporciona garantías sólidas de que el comportamiento permanece inalterado para todas las entradas no-buggy

**Test Plan**: Observar comportamiento en código SIN CORREGIR primero para mapeo de otros campos, luego escribir property-based tests capturando ese comportamiento.

**Test Cases**:
1. **Name Field Preservation**: Observar que el mapeo de name funciona correctamente en código sin corregir, luego verificar que continúa después de la corrección
2. **Description Field Preservation**: Observar que el mapeo de description funciona correctamente en código sin corregir, luego verificar que continúa después de la corrección
3. **Complex Object Preservation**: Observar que la conversión DTO→Entity funciona correctamente en código sin corregir, luego verificar que continúa después de la corrección

### Unit Tests

- Test de mapeo de campo equipment/category con diferentes estructuras JSON
- Test de casos edge (campo faltante, valor null, tipo incorrecto)
- Test de que otros campos continúan mapeándose correctamente

### Property-Based Tests

- Generar respuestas JSON aleatorias y verificar que el mapeo de equipment funciona correctamente
- Generar configuraciones de ejercicios aleatorias y verificar preservación del comportamiento de mapeo de otros campos
- Test que el mapeo funciona consistentemente a través de muchos escenarios

### Integration Tests

- Test de flujo completo de carga de ejercicios desde la API
- Test de que la información de equipment se muestra correctamente en la UI
- Test de que las operaciones de búsqueda y filtrado continúan funcionando con el campo equipment corregido