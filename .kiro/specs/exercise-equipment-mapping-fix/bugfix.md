# Bugfix Requirements Document

## Introduction

El campo equipment de los ejercicios aparece como null en la aplicación Flutter, mientras que las descriptions se muestran correctamente. Esto indica un problema de mapeo de datos entre el backend Spring Boot y el frontend Flutter, donde existe una discrepancia entre los nombres de campos esperados y los enviados por la API.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN la aplicación Flutter solicita ejercicios desde la API Spring Boot THEN el campo equipment aparece como null en la UI

1.2 WHEN el backend envía el campo "equipment" en la respuesta JSON THEN el ExerciseDto.fromJson() no puede mapear correctamente el campo porque busca "category"

1.3 WHEN se muestran 5 ejercicios en la UI THEN las descriptions aparecen diferentes a las almacenadas en la base de datos

### Expected Behavior (Correct)

2.1 WHEN la aplicación Flutter solicita ejercicios desde la API Spring Boot THEN el campo equipment SHALL mostrarse correctamente en la UI con el valor de la base de datos

2.2 WHEN el backend envía el campo "equipment" en la respuesta JSON THEN el ExerciseDto.fromJson() SHALL mapear correctamente el campo al atributo correspondiente en la entidad

2.3 WHEN se muestran ejercicios en la UI THEN las descriptions SHALL coincidir exactamente con las almacenadas en la base de datos

### Unchanged Behavior (Regression Prevention)

3.1 WHEN se cargan ejercicios que tienen descriptions válidas THEN el sistema SHALL CONTINUE TO mostrar las descriptions correctamente

3.2 WHEN se realizan otras operaciones con ejercicios (búsqueda, filtrado) THEN el sistema SHALL CONTINUE TO funcionar sin afectar la funcionalidad existente

3.3 WHEN se convierten DTOs a entidades del dominio THEN el sistema SHALL CONTINUE TO mantener la separación limpia entre capas de datos y dominio