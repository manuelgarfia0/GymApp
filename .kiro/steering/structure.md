# Project Structure

## Architecture Pattern
Feature-first clean architecture with clear separation between data, domain and UI/Presentation.

## Directory Organization

```
lib/
├── main.dart                    # Punto de entrada y configuración global
├── app.dart                     # Configuración de MaterialApp (temas, rutas) 
├── core/                        # Código compartido por toda la app 
│   ├── network/                 # Cliente API (Dio/Http) y constantes
│   ├── storage/                 # Persistencia local (Secure Storage)
│   ├── theme/                   # Estilos globales y temas
│   ├── utils/                   # Validadores y helpers comunes 
│   └── widgets/                 # Componentes UI reutilizables globalmente 
└── features/                    # Módulos de funcionalidades independientes 
    ├── auth/                    # Ejemplo: Funcionalidad de Autenticación
    │   ├── data/                # CAPA DE DATOS: Comunicación externa 
    │   │   ├── datasources/     # Peticiones crudas a la API de Spring Boot 
    │   │   ├── models/          # DTOs y mapeo de JSON 
    │   │   └── repositories/    # Implementación de los repositorios 
    │   ├── domain/              # CAPA DE DOMINIO: Lógica de negocio pura 
    │   │   ├── entities/        # Modelos de negocio simples (ej. User) 
    │   │   ├── repositories/    # Interfaces de los repositorios (contratos) 
    │   │   └── use_cases/       # Acciones específicas (ej. LoginUser) 
    │   └── presentation/        # CAPA DE PRESENTACIÓN: Interfaz de usuario 
    │       ├── bloc/            # Gestión de estado (BLoC, Riverpod, etc.) 
    │       ├── screens/         # Pantallas de la funcionalidad 
    │       └── widgets/         # Componentes UI exclusivos de esta feature
    ├── workouts/                # Funcionalidad de Rutinas (Misma estructura interna)
    └── tracking/                # Funcionalidad de Registro (Misma estructura interna)
```

## Conventions

### Feature Module Structure
Each feature follows this pattern:
- Domain: Debe ser Dart puro, sin dependencias de Flutter. Contiene las entidades y los "Casos de Uso" que dictan qué hace la app.
- Data: Aquí se gestiona el JSON que viene de tu backend Java. Los models (DTOs) extienden las entities del dominio para añadir lógica de serialización.
- UI/Presentation: Solo se encarga de mostrar datos y capturar eventos. No debe contener lógica de negocio; esta se delega a los casos de uso a través del gestor de estado


### Naming Conventions
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/functions: `camelCase`
- Constants: `camelCase` (with `const` keyword)
- Private members: prefix with `_`

### Code Organization
- Core utilities are shared across all features
- Features are self-contained and independent
- API client automatically injects JWT tokens
- Secure storage for sensitive data (tokens)
- Material Design 3 with dark theme throughout

### Best Practices
- Imports: Usar imports relativos para el código dentro de la misma funcionalidad para facilitar el refactor y mantener los archivos limpios.
- Separación de Modelos: No uses la misma clase para recibir datos de la API (DTO) y para mostrarlos en la UI (Entity). Esto permite que si cambias tu API en Spring Boot, solo afecte a la capa de Datos.
- Testing: La carpeta test/ debe imitar exactamente la estructura de lib/ para organizar los unit tests de cada caso de uso y repositorio

### API Integration
- Todas las llamadas pasan por la capa de data/datasources.
- Endpoints defined in `ApiConstants`
- Services handle HTTP requests and error handling
- JSON serialization for request/response bodies

### State Management
- Currently using StatefulWidget for local state
- Services instantiated per-screen or as singletons
- Token persistence via `SecureStorageService`

### Navigation
- MaterialPageRoute for screen transitions
- Auth check on app startup redirects to Login or Home
- `Navigator.pushReplacement` for auth flows
