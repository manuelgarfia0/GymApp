# API Contract Fix Bugfix Design

## Overview

El sistema presenta un error crítico de contrato de comunicación HTTP entre la aplicación Flutter y la API Spring Boot. Las peticiones POST están siendo enviadas con Content-Type 'text/plain;charset=utf-8' en lugar del Content-Type 'application/json' esperado, causando errores 500 en el servidor. La solución requiere corregir la configuración del cliente HTTP en Flutter para asegurar que los headers JSON se apliquen correctamente a todas las peticiones que incluyen cuerpo JSON.

## Glossary

- **Bug_Condition (C)**: La condición que activa el bug - cuando Flutter envía peticiones POST con cuerpo JSON pero Content-Type incorrecto
- **Property (P)**: El comportamiento deseado cuando se envían peticiones POST - el Content-Type debe ser 'application/json'
- **Preservation**: El comportamiento existente de peticiones GET y otros métodos HTTP que debe mantenerse sin cambios
- **ApiClient**: La clase en `lib/core/network/api_client.dart` que extiende http.BaseClient y maneja la inyección de headers
- **AuthRemoteDatasource**: El servicio que utiliza ApiClient para realizar peticiones de autenticación
- **Content-Type Header**: El header HTTP que especifica el tipo de contenido del cuerpo de la petición

## Bug Details

### Bug Condition

El bug se manifiesta cuando Flutter envía peticiones POST con cuerpo JSON a cualquier endpoint de la API Spring Boot. El ApiClient está configurando el header Content-Type correctamente, pero el paquete `http` de Flutter está sobrescribiendo o ignorando este header, resultando en peticiones enviadas con 'text/plain;charset=utf-8'.

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type HttpRequest
  OUTPUT: boolean
  
  RETURN input.method == 'POST'
         AND input.hasJsonBody == true
         AND input.actualContentType == 'text/plain;charset=utf-8'
         AND input.expectedContentType == 'application/json'
END FUNCTION
```

### Examples

- **Login Request**: `POST /api/auth/login` with JSON body `{"username": "user", "password": "pass"}` sends Content-Type 'text/plain;charset=utf-8' instead of 'application/json'
- **Register Request**: `POST /api/auth/register` with JSON body sends incorrect Content-Type
- **Any POST with JSON**: All POST requests with JSON payloads exhibit this behavior
- **GET Requests**: Continue to work correctly as they don't require Content-Type headers

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- GET requests must continue to work exactly as before without Content-Type headers
- JWT token injection via Authorization header must remain unchanged
- Error handling and retry logic must remain unchanged
- Network diagnostics and logging must remain unchanged

**Scope:**
All HTTP requests that do NOT involve sending JSON bodies should be completely unaffected by this fix. This includes:
- GET requests to any endpoint
- Requests without bodies
- Future requests with different content types (if implemented)

## Hypothesized Root Cause

Based on the bug description and code analysis, the most likely issues are:

1. **HTTP Package Method Override**: The `http.post()` method may be overriding the Content-Type header set in the BaseClient
   - The `post()` method has its own header handling logic
   - It may default to 'text/plain' when receiving a String body

2. **Header Timing Issue**: The Content-Type header is being set in the `send()` method but may be overridden later
   - The `post()` method processes headers after the BaseClient

3. **Body Encoding Issue**: The way the JSON body is being passed to the `post()` method may trigger incorrect Content-Type detection
   - Using `jsonEncode()` returns a String, which may be interpreted as plain text

4. **HTTP Package Version Compatibility**: The current `http` package version (1.6.0) may have specific behavior with BaseClient header handling

## Correctness Properties

Property 1: Bug Condition - JSON Content-Type Headers

_For any_ HTTP POST request with a JSON body sent through the ApiClient, the fixed implementation SHALL send the request with Content-Type 'application/json', ensuring Spring Boot can properly parse the JSON payload and process the request successfully.

**Validates: Requirements 2.1, 2.2, 2.3, 2.4**

Property 2: Preservation - Non-JSON Request Behavior

_For any_ HTTP request that does not involve sending JSON bodies (GET requests, requests without bodies), the fixed ApiClient SHALL produce exactly the same behavior as the original implementation, preserving all existing functionality for non-JSON HTTP operations.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4**

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct:

**File**: `lib/core/network/api_client.dart`

**Function**: `send` method and potentially new helper methods

**Specific Changes**:
1. **Header Application Strategy**: Modify how Content-Type headers are applied to ensure they persist through the HTTP request lifecycle
   - Move Content-Type setting to a more explicit approach
   - Ensure headers are set after the request is fully constructed

2. **Request Method Handling**: Implement specific handling for POST requests with JSON bodies
   - Override the `post` method to ensure proper Content-Type handling
   - Use explicit header setting for JSON requests

3. **Body Type Detection**: Add logic to detect when a request body contains JSON content
   - Check if body is JSON-encoded string
   - Apply appropriate Content-Type based on body content

4. **Header Validation**: Add validation to ensure Content-Type headers are correctly applied
   - Log header values for debugging
   - Verify headers before sending requests

5. **Backward Compatibility**: Ensure changes don't break existing GET requests or other HTTP methods
   - Maintain current behavior for non-POST requests
   - Preserve JWT token injection logic

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on unfixed code, then verify the fix works correctly and preserves existing behavior.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm or refute the root cause analysis. If we refute, we will need to re-hypothesize.

**Test Plan**: Write tests that create HTTP POST requests with JSON bodies and inspect the actual Content-Type headers being sent. Run these tests on the UNFIXED code to observe the incorrect 'text/plain;charset=utf-8' headers and understand the root cause.

**Test Cases**:
1. **Login POST Test**: Create login request with JSON body and verify Content-Type header (will fail on unfixed code)
2. **Register POST Test**: Create register request with JSON body and verify Content-Type header (will fail on unfixed code)
3. **Generic POST Test**: Create any POST request with JSON body and verify Content-Type header (will fail on unfixed code)
4. **Header Inspection Test**: Intercept actual HTTP requests to verify headers being sent (will show 'text/plain' on unfixed code)

**Expected Counterexamples**:
- Content-Type headers will be 'text/plain;charset=utf-8' instead of 'application/json'
- Possible causes: HTTP package method override, header timing issues, body encoding problems

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds, the fixed function produces the expected behavior.

**Pseudocode:**
```
FOR ALL input WHERE isBugCondition(input) DO
  result := apiClient_fixed.post(input.url, body: input.jsonBody)
  ASSERT result.requestHeaders['Content-Type'] == 'application/json'
  ASSERT result.serverResponse.statusCode != 500 (due to Content-Type)
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold, the fixed function produces the same result as the original function.

**Pseudocode:**
```
FOR ALL input WHERE NOT isBugCondition(input) DO
  ASSERT apiClient_original.send(input) = apiClient_fixed.send(input)
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many test cases automatically across the input domain
- It catches edge cases that manual unit tests might miss
- It provides strong guarantees that behavior is unchanged for all non-buggy inputs

**Test Plan**: Observe behavior on UNFIXED code first for GET requests and other HTTP methods, then write property-based tests capturing that behavior.

**Test Cases**:
1. **GET Request Preservation**: Verify GET requests continue to work without Content-Type headers
2. **JWT Token Preservation**: Verify Authorization headers are still injected correctly
3. **Error Handling Preservation**: Verify network errors and exceptions are handled the same way
4. **Other HTTP Methods Preservation**: Verify PUT, DELETE, PATCH methods (if used) continue working

### Unit Tests

- Test ApiClient header injection for POST requests with JSON bodies
- Test that GET requests don't receive unnecessary Content-Type headers
- Test JWT token injection continues to work across all request types
- Test edge cases (empty bodies, null bodies, non-JSON bodies)

### Property-Based Tests

- Generate random JSON payloads and verify all POST requests get correct Content-Type
- Generate random request configurations and verify preservation of non-POST behavior
- Test that all authentication flows work correctly across many scenarios

### Integration Tests

- Test full login flow with corrected Content-Type headers
- Test registration flow with proper JSON Content-Type
- Test that Spring Boot successfully processes requests with correct headers
- Test error scenarios return appropriate HTTP status codes (401, 403) instead of 500