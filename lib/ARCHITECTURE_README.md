# Clean Architecture Structure

This project follows Clean Architecture principles to ensure maintainability, testability, and scalability.

## Folder Structure

```
lib/
├── data/                    # Data Layer
│   ├── datasources/
│   │   ├── local/          # Local database (Hive/SQLite)
│   │   ├── remote/         # API calls (HTTP/Firebase)
│   │   └── models/         # DTOs (Data Transfer Objects)
│   └── repositories/       # Repository implementations
│
├── domain/                  # Domain Layer (Business Logic)
│   ├── entities/           # Core business entities
│   ├── repositories/       # Repository interfaces
│   └── usecases/           # Business logic use cases
│
├── presentation/            # Presentation Layer (UI)
│   ├── common/
│   │   ├── widgets/        # Reusable widgets
│   │   └── styles/         # Colors, themes, text styles
│   └── features/           # Feature modules
│       ├── auth/           # Authentication screens
│       └── dashboard/      # Dashboard screens
│
└── utils/                   # Utilities & Helpers
    ├── constants.dart
    └── helper_functions.dart
```

## Layer Responsibilities

### Domain Layer (Business Logic)
- **Entities**: Pure Dart classes representing business objects
- **Repositories**: Abstract interfaces defining contracts
- **Use Cases**: Business logic that orchestrates data flow

**Key Rule**: Domain layer should NOT depend on any other layer!

### Data Layer
- **Models**: Convert between API/DB format and Entities
- **Data Sources**:
  - `remote`: API calls (Firebase, REST API)
  - `local`: Cache (Hive, SQLite) for offline capability
- **Repositories**: Implement domain interfaces, decide when to use remote vs local

### Presentation Layer
- **Screens**: Full page widgets
- **Widgets**: Reusable UI components
- **State Management**: Handle UI state (Provider, Riverpod, Bloc, etc.)

## Data Flow

```
UI (Presentation)
  ↓ calls
Use Case (Domain)
  ↓ calls
Repository Interface (Domain)
  ↓ implemented by
Repository Implementation (Data)
  ↓ calls
Data Source (Local/Remote)
  ↓ returns
Models (Data)
  ↓ converts to
Entities (Domain)
  ↓ returns to
UI (Presentation)
```

## Benefits

1. **Separation of Concerns**: Each layer has a single responsibility
2. **Testability**: Easy to unit test business logic
3. **Maintainability**: Changes in one layer don't affect others
4. **Scalability**: Easy to add new features
5. **Team Collaboration**: Multiple developers can work on different layers

## Next Steps

1. Implement actual data sources (Firebase, Hive, etc.)
2. Add state management (Provider, Riverpod, Bloc)
3. Create more entities and use cases
4. Build out the presentation layer with proper screens
